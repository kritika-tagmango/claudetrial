import { useState, useEffect } from "react";

const SYSTEM_PROMPT = `You are an expert sales coach and conversation analyst for TagMango — a SaaS platform that helps coaches, creators, and educators host courses, webinars, communities, and digital products.

Key platform features:
- LMS (courses, modules, certificates)
- Live sessions via Zoom/Google Meet integration
- White-labeled dashboard (Freedom Setup = web only, Enterprise Setup = web + Android/iOS app + custom website + success manager)
- Payment gateways (Razorpay, Paytm, Stripe for international)
- WhatsApp API automation + email automation
- Community features (feed, messages, Discord-style channel groups)
- Gamification (points, badges, leaderboard) — Advanced plan
- Level Up (habit tracker, challenges, certifications) — Ultimate plan
- Affiliate system, Linkup (coach collaboration), no-cost EMI
- Subscription plans: Basic (10% commission, no recurring), Pro (5K/month, 5%), Advanced (15K/month, 2.5%), Ultimate (no commission, gateway fees only)
- Setup costs: Freedom (25K one-time), Enterprise (1L one-time, discounted to 80K for ILH members)

The salesperson is Kritika. When given a meeting transcript, produce a full structured analysis. Every insight must be specific to the transcript — no generic advice. NEVER include private internal notes in follow-up messages.

Return your response as a JSON object with this exact structure:
{
  "leadName": "string",
  "callCount": number,
  "sections": {
    "deepAnalysis": {
      "whoIsThisLead": ["string — one crisp pointer per item, max 10 words each"],
      "coreGoals": ["string — one crisp pointer per item, max 10 words each"],
      "painPoints": ["string — one crisp pointer per item, max 10 words each"],
      "hiddenMotivations": ["string — one crisp pointer per item, max 10 words each"],
      "objections": ["string"],
      "leadStage": "string",
      "leadStageLabel": "Beginner / Testing | Early Revenue | Scaling | Advanced / Institutional"
    },
    "segmentation": {
      "primarySegment": "string",
      "primarySegmentLabel": "Community / High-ticket focused | Tech / App-focused | Branding / Authority-focused | Lead-gen focused | Institutional / B2B",
      "customSubSegment": "string"
    },
    "probabilityToClose": {
      "rating": "High | Medium-High | Medium | Low",
      "percentage": number,
      "movingForward": "string",
      "blocking": "string"
    },
    "gaps": [{ "title": "string", "body": "string" }],
    "improvements": [{ "title": "string", "body": "string" }],
    "followUp": {
      "whatsapp": "string",
      "emailSubject": "string",
      "emailBody": "string"
    },
    "urgency": "string | null"
  }
}

Return ONLY valid JSON. No markdown, no backticks, no preamble.`;

const ratingMeta = {
  "High":        { bg: "#081A12", text: "#5DCAA5", border: "#0A2818", bar: "#1D9E75" },
  "Medium-High": { bg: "#081A12", text: "#5DCAA5", border: "#0A2818", bar: "#1D9E75" },
  "Medium":      { bg: "#221A08", text: "#EF9F27", border: "#3A2808", bar: "#EF9F27" },
  "Low":         { bg: "#1A0808", text: "#E24B4A", border: "#2A1010", bar: "#E24B4A" },
};

const STORAGE_PREFIX = "call:";

async function loadAllCalls() {
  try {
    const result = await window.storage.list(STORAGE_PREFIX);
    const keys = result?.keys || [];
    const calls = [];
    for (const key of keys) {
      try {
        const r = await window.storage.get(key);
        if (r?.value) calls.push({ key, ...JSON.parse(r.value) });
      } catch {}
    }
    return calls.sort((a, b) => b.savedAt - a.savedAt);
  } catch { return []; }
}

async function saveCall(analysis, transcript) {
  const key = `${STORAGE_PREFIX}${Date.now()}`;
  await window.storage.set(key, JSON.stringify({ ...analysis, transcript, savedAt: Date.now() }));
  return key;
}

async function deleteCall(key) { await window.storage.delete(key); }

function fmt(ts) {
  return new Date(ts).toLocaleDateString("en-IN", { day: "numeric", month: "short", year: "numeric" });
}

export default function App() {
  const [view, setView] = useState("list");
  const [transcript, setTranscript] = useState("");
  const [analysis, setAnalysis] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [activeTab, setActiveTab] = useState("whatsapp");
  const [copied, setCopied] = useState("");
  const [calls, setCalls] = useState([]);
  const [callsLoading, setCallsLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [deletingKey, setDeletingKey] = useState(null);

  useEffect(() => {
    loadAllCalls().then(c => { setCalls(c); setCallsLoading(false); });
  }, []);

  const analyze = async () => {
    if (!transcript.trim()) return;
    setLoading(true);
    setError("");
    setAnalysis(null);
    setView("analysis");
    try {
      const res = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": import.meta.env.VITE_ANTHROPIC_API_KEY,
          "anthropic-version": "2023-06-01",
          "anthropic-dangerous-direct-browser-access": "true",
        },
        body: JSON.stringify({
          model: "claude-sonnet-4-20250514",
          max_tokens: 4000,
          system: SYSTEM_PROMPT,
          messages: [{ role: "user", content: "Analyse this transcript:\n\n" + transcript }],
        }),
      });
      const data = await res.json();
      const raw = data.content?.[0]?.text || "";
      const parsed = JSON.parse(raw.replace(/```json|```/g, "").trim());
      const key = await saveCall(parsed, transcript);
      const saved = { key, ...parsed, transcript, savedAt: Date.now() };
      setAnalysis(saved);
      setCalls(prev => [saved, ...prev]);
    } catch {
      setError("Something went wrong. Check the transcript and try again.");
      setView("new");
    }
    setLoading(false);
  };

  const openCall = (call) => { setAnalysis(call); setActiveTab("whatsapp"); setView("analysis"); };

  const handleDelete = async (key, e) => {
    e.stopPropagation();
    setDeletingKey(key);
    await deleteCall(key);
    setCalls(prev => prev.filter(c => c.key !== key));
    setDeletingKey(null);
    if (analysis?.key === key) { setAnalysis(null); setView("list"); }
  };

  const copy = (text, k) => {
    navigator.clipboard.writeText(text);
    setCopied(k);
    setTimeout(() => setCopied(""), 2000);
  };

  const filtered = calls.filter(c => c.leadName?.toLowerCase().includes(search.toLowerCase()));
  const d = analysis?.sections;

  return (
    <div style={{ display: "flex", height: "100vh", background: "#0C0E0F", fontFamily: "'DM Mono','Courier New',monospace", color: "#E8E4DC", overflow: "hidden" }}>
      <link href="https://fonts.googleapis.com/css2?family=DM+Mono:wght@300;400;500&family=Playfair+Display:ital,wght@0,400;1,400&display=swap" rel="stylesheet" />
      <style>{`
        *{box-sizing:border-box}
        ::-webkit-scrollbar{width:3px}
        ::-webkit-scrollbar-track{background:transparent}
        ::-webkit-scrollbar-thumb{background:#222;border-radius:2px}
        .sidebar{width:240px;min-width:240px;border-right:.5px solid #1E2022;display:flex;flex-direction:column;background:#0A0C0D}
        .main{flex:1;overflow-y:auto;padding:2rem 2.5rem}
        .card{background:#141618;border:.5px solid #2A2D2F;border-radius:12px;padding:1.25rem 1.5rem;margin-bottom:.875rem}
        .card-label{font-size:10px;letter-spacing:.12em;text-transform:uppercase;color:#555;margin:0 0 8px}
        .card-value{font-size:13px;line-height:1.7;color:#C8C4BC;margin:0}
        .badge{display:inline-block;font-size:10px;font-weight:500;padding:3px 10px;border-radius:20px;margin:2px 3px 2px 0;letter-spacing:.04em}
        .badge-coral{background:#2A1510;color:#F0997B;border:.5px solid #4A2010}
        .badge-teal{background:#081A12;color:#5DCAA5;border:.5px solid #0A2818}
        .badge-blue{background:#081520;color:#85B7EB;border:.5px solid #0C2035}
        .gap-item{border-left:2px solid #E24B4A;padding-left:14px;margin-bottom:14px}
        .imp-item{border-left:2px solid #1D9E75;padding-left:14px;margin-bottom:14px}
        .item-title{font-size:13px;font-weight:500;margin:0 0 5px;color:#E8E4DC}
        .item-body{font-size:12px;line-height:1.65;color:#777;margin:0}
        .sec-title{font-size:10px;letter-spacing:.14em;text-transform:uppercase;color:#444;margin:0 0 .85rem}
        .tab-btn{font-family:'DM Mono',monospace;font-size:11px;padding:6px 14px;border-radius:6px;border:.5px solid #2A2D2F;cursor:pointer;letter-spacing:.05em;transition:all .15s}
        .tab-active{background:#E8E4DC;color:#0C0E0F;border-color:#E8E4DC}
        .tab-inactive{background:transparent;color:#555}
        .tab-inactive:hover{background:#1A1C1E;color:#AAA}
        .msg-box{background:#0A0C0D;border:.5px solid #2A2D2F;border-radius:10px;padding:1.25rem;font-size:12px;line-height:1.8;color:#999;white-space:pre-wrap;font-family:'DM Mono',monospace}
        .copy-btn{font-family:'DM Mono',monospace;font-size:10px;letter-spacing:.08em;padding:5px 12px;border-radius:6px;border:.5px solid #2A2D2F;background:transparent;color:#555;cursor:pointer;transition:all .15s}
        .copy-btn:hover{background:#1A1C1E;color:#AAA}
        .copy-done{background:#081A12 !important;color:#5DCAA5 !important;border-color:#0A2818 !important}
        .analyze-btn{font-family:'DM Mono',monospace;font-size:12px;letter-spacing:.1em;padding:13px 28px;border-radius:8px;border:none;background:#E8E4DC;color:#0C0E0F;cursor:pointer;font-weight:500;transition:all .2s;width:100%}
        .analyze-btn:hover:not(:disabled){background:#D0CCC4;transform:translateY(-1px)}
        .analyze-btn:disabled{opacity:.35;cursor:not-allowed;transform:none}
        .grid2{display:grid;grid-template-columns:repeat(auto-fit,minmax(190px,1fr));gap:10px}
        .prob-bar-bg{background:#1A1C1E;border-radius:999px;height:5px;overflow:hidden;margin:8px 0 12px}
        .divider{border:none;border-top:.5px solid #1A1C1E;margin:1.75rem 0}
        textarea{resize:none;outline:none}
        textarea::placeholder{color:#2E3032}
        .fade-in{animation:fadeIn .35s ease forwards}
        @keyframes fadeIn{from{opacity:0;transform:translateY(6px)}to{opacity:1;transform:translateY(0)}}
        .call-row{padding:.7rem 1rem;cursor:pointer;border-bottom:.5px solid #111;transition:background .1s;display:flex;align-items:center;justify-content:space-between;gap:8px}
        .call-row:hover{background:#0F1113}
        .call-row.active{background:#141618;border-left:2px solid #5DCAA5}
        .del-btn{font-size:10px;color:#2A2D2F;background:transparent;border:none;cursor:pointer;padding:3px 5px;border-radius:4px;transition:color .15s;flex-shrink:0}
        .del-btn:hover{color:#E24B4A}
        .icon-btn{font-family:'DM Mono',monospace;font-size:10px;letter-spacing:.08em;padding:5px 10px;border-radius:6px;border:.5px solid #2A2D2F;background:transparent;color:#555;cursor:pointer;transition:all .15s}
        .icon-btn:hover{background:#1A1C1E;color:#AAA}
        .search-input{width:100%;background:#0A0C0D;border:none;border-bottom:.5px solid #1E2022;padding:.6rem 1rem;font-family:'DM Mono',monospace;font-size:11px;color:#888;outline:none}
        .search-input::placeholder{color:#222}
        .loading-dots span{animation:blink 1.4s infinite both;display:inline-block}
        .loading-dots span:nth-child(2){animation-delay:.2s}
        .loading-dots span:nth-child(3){animation-delay:.4s}
        @keyframes blink{0%,80%,100%{opacity:0}40%{opacity:1}}
        .empty-state{text-align:center;padding:3rem 1rem;color:#2A2D2F;font-size:11px;line-height:2}
        .rating-badge{display:inline-block;font-size:10px;font-weight:500;padding:3px 10px;border-radius:20px;letter-spacing:.04em}
      `}</style>

      {/* ── Sidebar ── */}
      <div className="sidebar">
        <div style={{ padding: "1rem 1rem .75rem", borderBottom: ".5px solid #1E2022" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: ".4rem" }}>
            <div style={{ width: 6, height: 6, borderRadius: "50%", background: "#E24B4A" }} />
            <span style={{ fontSize: 10, letterSpacing: ".18em", textTransform: "uppercase", color: "#3A3D3F" }}>TagMango</span>
          </div>
          <p style={{ fontFamily: "'Playfair Display',serif", fontSize: 14, fontStyle: "italic", color: "#555", margin: 0 }}>Call Analyser</p>
        </div>

        <button
          onClick={() => { setView("new"); setAnalysis(null); setTranscript(""); setError(""); }}
          style={{ margin: ".75rem .75rem .25rem", fontFamily: "'DM Mono',monospace", fontSize: 11, letterSpacing: ".08em", padding: "9px 14px", borderRadius: 7, border: ".5px solid #2A2D2F", background: view === "new" ? "#E8E4DC" : "transparent", color: view === "new" ? "#0C0E0F" : "#555", cursor: "pointer", transition: "all .15s", textAlign: "left" }}>
          + NEW CALL
        </button>

        <input className="search-input" placeholder="search leads..." value={search} onChange={e => setSearch(e.target.value)} style={{ marginTop: ".25rem" }} />

        <div style={{ flex: 1, overflowY: "auto" }}>
          {callsLoading ? (
            <div style={{ padding: "2rem", textAlign: "center" }}>
              <div className="loading-dots" style={{ fontSize: 18, color: "#222", letterSpacing: 4 }}><span>.</span><span>.</span><span>.</span></div>
            </div>
          ) : filtered.length === 0 ? (
            <div className="empty-state">{search ? "no leads found." : "no calls yet.\nanalyse your first call."}</div>
          ) : filtered.map(c => (
            <div key={c.key} className={"call-row" + (analysis?.key === c.key ? " active" : "")} onClick={() => openCall(c)}>
              <div style={{ minWidth: 0 }}>
                <p style={{ margin: 0, fontSize: 12, color: "#C8C4BC", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{c.leadName}</p>
                <p style={{ margin: "2px 0 0", fontSize: 10, color: "#333" }}>{fmt(c.savedAt)} · {c.callCount} {c.callCount === 1 ? "call" : "calls"}</p>
              </div>
              <button className="del-btn" onClick={(e) => handleDelete(c.key, e)} disabled={deletingKey === c.key}>✕</button>
            </div>
          ))}
        </div>

        <div style={{ padding: ".75rem 1rem", borderTop: ".5px solid #111" }}>
          <p style={{ margin: 0, fontSize: 10, color: "#222", letterSpacing: ".06em" }}>{calls.length} CALL{calls.length !== 1 ? "S" : ""} STORED</p>
        </div>
      </div>

      {/* ── Main ── */}
      <div className="main">

        {/* New call */}
        {view === "new" && (
          <div className="fade-in">
            <div style={{ marginBottom: "1.75rem" }}>
              <p style={{ fontFamily: "'Playfair Display',serif", fontSize: 28, fontWeight: 400, margin: "0 0 .3rem", lineHeight: 1.2 }}>Paste your transcript.</p>
              <p style={{ fontSize: 12, color: "#444", margin: 0 }}>Single or multiple calls — full 7-point analysis, saved automatically.</p>
            </div>
            <textarea
              value={transcript}
              onChange={e => setTranscript(e.target.value)}
              placeholder={"Me: Hope you're doing well...\nThem: Yes, wanted to ask about your platform...\n\n// Paste one or multiple call transcripts here"}
              style={{ width: "100%", height: 280, background: "#0A0C0D", border: ".5px solid #2A2D2F", borderRadius: 12, padding: "1.25rem 1.5rem", fontSize: 12, lineHeight: 1.75, color: "#888", fontFamily: "'DM Mono',monospace", marginBottom: "1rem" }}
            />
            {error && <p style={{ fontSize: 12, color: "#E24B4A", marginBottom: ".75rem" }}>{error}</p>}
            <button className="analyze-btn" onClick={analyze} disabled={!transcript.trim()}>ANALYSE CALL →</button>
          </div>
        )}

        {/* Loading */}
        {view === "analysis" && loading && (
          <div style={{ textAlign: "center", paddingTop: "6rem" }}>
            <p style={{ fontFamily: "'Playfair Display',serif", fontSize: 22, color: "#333", fontStyle: "italic", margin: "0 0 1rem" }}>Reading the room</p>
            <div className="loading-dots" style={{ fontSize: 24, color: "#222", letterSpacing: 4 }}><span>.</span><span>.</span><span>.</span></div>
          </div>
        )}

        {/* Empty landing */}
        {view === "list" && !loading && (
          <div className="fade-in" style={{ textAlign: "center", paddingTop: "5rem" }}>
            <p style={{ fontFamily: "'Playfair Display',serif", fontSize: 24, color: "#222", fontStyle: "italic", margin: "0 0 .5rem" }}>
              {calls.length > 0 ? "Select a call from the sidebar." : "No calls yet."}
            </p>
            <p style={{ fontSize: 12, color: "#2A2D2F", margin: "0 0 1.5rem" }}>Paste a transcript to get started.</p>
            <button className="analyze-btn" style={{ maxWidth: 240, margin: "0 auto", display: "block" }} onClick={() => { setView("new"); setTranscript(""); }}>+ NEW CALL</button>
          </div>
        )}

        {/* Analysis */}
        {view === "analysis" && !loading && analysis && d && (
          <div className="fade-in">
            <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", gap: 12, marginBottom: "1.75rem" }}>
              <div>
                <p style={{ fontFamily: "'Playfair Display',serif", fontSize: 26, fontWeight: 400, margin: "0 0 4px", lineHeight: 1.2 }}>{analysis.leadName}</p>
                <p style={{ fontSize: 11, color: "#444", margin: 0, letterSpacing: ".08em" }}>
                  {analysis.callCount} {analysis.callCount === 1 ? "call" : "calls"} · {fmt(analysis.savedAt)}
                </p>
              </div>
              <button className="icon-btn" onClick={() => { setView("new"); setTranscript(analysis.transcript || ""); setAnalysis(null); }}>RE-ANALYSE</button>
            </div>

            <hr className="divider" />

            {/* 01 */}
            <p className="sec-title">01 — Deep conversation analysis</p>
            {[
              { label: "Who is this lead?", key: "whoIsThisLead" },
              { label: "Core goals", key: "coreGoals" },
              { label: "Pain points", key: "painPoints" },
              { label: "Hidden motivations", key: "hiddenMotivations" },
            ].map(({ label, key }) => (
              <div className="card" key={key}>
                <p className="card-label">{label}</p>
                <ul style={{ margin: 0, padding: 0, listStyle: "none" }}>
                  {(Array.isArray(d.deepAnalysis[key]) ? d.deepAnalysis[key] : [d.deepAnalysis[key]]).map((pt, i) => (
                    <li key={i} style={{ fontSize: 13, color: "#C8C4BC", lineHeight: 1.65, marginBottom: 4, display: "flex", gap: 8, alignItems: "flex-start" }}>
                      <span style={{ color: "#3A3D3F", fontSize: 11, marginTop: 3, flexShrink: 0 }}>—</span>
                      <span>{pt}</span>
                    </li>
                  ))}
                </ul>
              </div>
            ))}
            <div className="card">
              <p className="card-label">Objections & hesitations</p>
              <div>{d.deepAnalysis.objections.map((o, i) => <span key={i} className="badge badge-coral">{o}</span>)}</div>
            </div>
            <div className="card">
              <p className="card-label">Lead stage</p>
              <span className="badge badge-blue">{d.deepAnalysis.leadStageLabel}</span>
              <p className="card-value" style={{ marginTop: 8 }}>{d.deepAnalysis.leadStage}</p>
            </div>

            <hr className="divider" />

            {/* 02 */}
            <p className="sec-title">02 — Lead segmentation</p>
            <div className="grid2">
              <div className="card">
                <p className="card-label">Primary segment</p>
                <span className="badge badge-teal">{d.segmentation.primarySegmentLabel}</span>
                <p className="card-value" style={{ marginTop: 8 }}>{d.segmentation.primarySegment}</p>
              </div>
              <div className="card">
                <p className="card-label">Custom sub-segment</p>
                <p className="card-value">{d.segmentation.customSubSegment}</p>
              </div>
            </div>

            <hr className="divider" />

            {/* 03 */}
            <p className="sec-title">03 — Probability to close</p>
            {(() => {
              const m = ratingMeta[d.probabilityToClose.rating] || ratingMeta["Medium"];
              return <>
                <span className="rating-badge" style={{ background: m.bg, color: m.text, border: ".5px solid " + m.border, marginBottom: 4 }}>{d.probabilityToClose.rating}</span>
                <div className="prob-bar-bg"><div style={{ background: m.bar, height: 5, borderRadius: 999, width: d.probabilityToClose.percentage + "%", transition: "width 1.2s ease" }} /></div>
              </>;
            })()}
            <div className="grid2">
              <div className="card"><p className="card-label">Moving forward</p><p className="card-value">{d.probabilityToClose.movingForward}</p></div>
              <div className="card"><p className="card-label">Blocking</p><p className="card-value">{d.probabilityToClose.blocking}</p></div>
            </div>

            <hr className="divider" />

            {/* 04 */}
            <p className="sec-title">04 — Gaps in the conversation</p>
            {d.gaps.map((g, i) => <div key={i} className="gap-item"><p className="item-title">{g.title}</p><p className="item-body">{g.body}</p></div>)}

            <hr className="divider" />

            {/* 05 */}
            <p className="sec-title">05 — How to improve the pitch</p>
            {d.improvements.map((imp, i) => <div key={i} className="imp-item"><p className="item-title">{imp.title}</p><p className="item-body">{imp.body}</p></div>)}

            <hr className="divider" />

            {/* 06 */}
            <p className="sec-title">06 — Follow-up messages</p>
            <div style={{ display: "flex", gap: 8, marginBottom: "1rem" }}>
              {["whatsapp", "email"].map(t => (
                <button key={t} className={"tab-btn " + (activeTab === t ? "tab-active" : "tab-inactive")} onClick={() => setActiveTab(t)}>{t.toUpperCase()}</button>
              ))}
            </div>
            {activeTab === "whatsapp" && <>
              <div className="msg-box">{d.followUp.whatsapp}</div>
              <button className={"copy-btn " + (copied === "wa" ? "copy-done" : "")} style={{ marginTop: 8 }} onClick={() => copy(d.followUp.whatsapp, "wa")}>{copied === "wa" ? "✓ COPIED" : "COPY MESSAGE"}</button>
            </>}
            {activeTab === "email" && <>
              <div style={{ marginBottom: 10 }}>
                <p className="card-label">Subject</p>
                <p style={{ fontSize: 13, color: "#C8C4BC", margin: 0, fontStyle: "italic" }}>{d.followUp.emailSubject}</p>
              </div>
              <div className="msg-box">{d.followUp.emailBody}</div>
              <button className={"copy-btn " + (copied === "em" ? "copy-done" : "")} style={{ marginTop: 8 }} onClick={() => copy("Subject: " + d.followUp.emailSubject + "\n\n" + d.followUp.emailBody, "em")}>{copied === "em" ? "✓ COPIED" : "COPY EMAIL"}</button>
            </>}

            {d.urgency && <>
              <hr className="divider" />
              <p className="sec-title">07 — Urgency angle</p>
              <div className="card"><p className="card-value">{d.urgency}</p></div>
            </>}

            <div style={{ height: "3rem" }} />
          </div>
        )}
      </div>
    </div>
  );
}

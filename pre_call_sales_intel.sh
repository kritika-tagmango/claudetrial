#!/bin/bash
# Pre-call sales intelligence — Kritika Gupta, TagMango
# Scheduled: 10:30 AM IST daily (05:00 UTC)
# Fetches Calendly bookings, enriches each lead, posts briefs to #lead-briefs

TODAY=$(date +"%Y-%m-%d")
TODAY_DISPLAY=$(date +"%d %B %Y")

# 10:30 AM IST = UTC+5:30, so use +05:30 offset for Calendly time filters
MIN_START="${TODAY}T00:00:00+05:30"
MAX_START="${TODAY}T23:59:59+05:30"

claude -p "
You are a pre-call sales intelligence assistant for Kritika Gupta, sales associate at TagMango.
Today is ${TODAY_DISPLAY}.

Work through the following steps in order. Be thorough — every piece of enrichment data improves the brief quality.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 1 — FETCH TODAY'S CALENDLY BOOKINGS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Call get_current_user to get the authenticated user's URI.
2. Call list_events with:
   - organization or user URI from above
   - min_start_time: ${MIN_START}
   - max_start_time: ${MAX_START}
   - status: active
3. For each event returned, call list_event_invitees to get the invitee details and form answers.
4. FILTER OUT any invitee whose email ends with @tagmango.com (internal team).
5. Sort remaining events chronologically by start time.
6. If zero external events remain after filtering, post to #lead-briefs (channel_id: C0AV08273PE):
   '✅ No client calls scheduled for today.'
   Then stop — do not proceed further.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 2 — EXTRACT FORM DATA FOR EACH LEAD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

From the invitee data for each external lead, extract the following fields (map question text to field names flexibly):
- Full name and email
- WhatsApp / phone number
- Social profile link (Instagram / YouTube / LinkedIn / Twitter — take whichever is present)
- Website URL (if provided)
- What they sell: course / workshop / community / other
- Current platform they use (e.g., Kajabi, Graphy, WhatsApp, Teachable, Thinkific, Skool, etc.)
- Paid community strength (number of paying members)
- Timeline to move to TagMango
- Expectations / goals from the call
- How they heard about TagMango

If any field is missing from the form, mark it as 'Not provided'.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 3 — ENRICH EACH LEAD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

For each lead, gather additional intelligence using web tools:

A) Social profile enrichment (if social link provided):
   - WebFetch the profile page OR WebSearch '[name] [platform] creator' to find:
     follower/subscriber count, posting niche, content type, estimated engagement,
     audience size signals, any products or courses they currently sell or promote.

B) Website enrichment (if website URL provided):
   - WebFetch the website to understand:
     products offered, pricing tiers, platforms/tools they use (check footer, integrations page),
     testimonials or community size signals, brand positioning.

C) Domain search fallback (if neither social nor website provided):
   - WebSearch the email domain (e.g., 'brandname.com') to find their brand/company.

D) Competitor intelligence (if a current platform is named):
   - Note the platform and identify the 2-3 strongest TagMango advantages specific to that competitor
     using the product context below.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 4 — GENERATE A BRIEF FOR EACH LEAD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Produce the following exact structure for each lead (replace all [placeholders]):

---
📞 CALL [N of Total] — [Full Name] | [HH:MM AM/PM IST]

🔹 WHO IS THIS LEAD
[2-3 sentences covering their business, background, estimated scale, and where they are in their creator/coach journey]

🔹 PROFILE SNAPSHOT
| Field | Detail |
|---|---|
| Name | [full name] |
| Email | [email] |
| WhatsApp | [number or Not provided] |
| Social Profile | [link or Not provided] |
| Niche | [detected niche from enrichment or form] |
| What They Sell | [course / workshop / community / other] |
| Current Platform | [platform or None mentioned] |
| Community Size | [number or Not provided] |
| Timeline | [timeline] |
| Source | [how they heard about TagMango] |

🔹 SOCIAL & WEB INTELLIGENCE
[Concrete findings from enrichment — follower count, engagement rate if estimable, content type, products, pricing found, platforms used, any notable brand signals. If nothing was found, say 'No public data found.']

🔹 LEAD TEMPERATURE: [🔥 Hot / ☀️ Warm / ❄️ Cold]
[One sentence reason referencing timeline, community size, and intent signals]

Temperature scoring guide:
- 🔥 Hot: Timeline ≤ 1 month AND community > 100 members AND clear monetization intent
- ☀️ Warm: Timeline 1–3 months OR moderate community OR still exploring options
- ❄️ Cold: Timeline > 3 months OR very small / no community OR vague intent

🔹 RECOMMENDED SETUP & PLAN
Setup: [Freedom or Enterprise] — [specific reason based on their needs, e.g., app requirement, brand, scale]
Plan: [Basic / Pro / Advanced / Ultimate] — [reason tied to community size and commission sensitivity]
Most relevant TagMango features for this lead: [list 2–3 specific features, e.g., Live sessions, Course builder, Community feed, Branded app, Certificates, Drip content]

🔹 KEY TALKING POINTS
1. [Specific point tied to their niche, current platform pain point, or expectations]
2. [Specific point]
3. [Specific point]

🔹 COMPETITOR ANGLE
[If a current platform was named: list 2–3 strongest TagMango advantages over that specific platform. Be concrete — e.g., 'Graphy charges X whereas TagMango's Basic plan has zero monthly fee'. If no competitor mentioned, write 'No competitor mentioned — lead is platform-agnostic.']

🔹 WATCH OUT
[Red flags, misfit signals, or cautions for Kritika — e.g., very small audience, lead-gen only focus, expects features TagMango doesn't offer, timeline too far out, price sensitivity signals]

---

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 5 — SEND ONE CONSOLIDATED SLACK MESSAGE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Post a SINGLE message to #lead-briefs (channel_id: C0AV08273PE) with this structure:

First line:
📋 Today's Call Briefs — ${TODAY_DISPLAY} | [X] call[s] scheduled

Then insert each lead brief in chronological order, separated by the --- divider exactly as written above.

Close with a summary table:

📊 SUMMARY
| Lead Name | Call Time | Temperature | Recommended Plan | Priority Action |
|---|---|---|---|---|
[one row per lead — Priority Action should be a 3-5 word call-to-action e.g., 'Push for Enterprise close', 'Nurture — timeline far', 'Qualify community size first']

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TAGMANGO PRODUCT REFERENCE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Platform: All-in-one SaaS for coaches and creators — courses, communities, digital products on an owned platform.

Setups (both ₹1,00,000 one-time):
- Freedom: Web only
- Enterprise: Branded Android + iOS app, custom website, dedicated success manager

Plans:
- Basic:    ₹0/month    | 10% commission
- Pro:      ₹5K/month   | 5% commission
- Advanced: ₹15K/month  | 2.5% commission
- Ultimate: ₹30K/month  | 0% commission

Key differentiator: Owned platform vs rented land (WhatsApp groups, Instagram, LinkedIn, Telegram).

Strong fit: Health/fitness, career/productivity, trading/finance, tech/coding coaches; creators with existing engaged communities.
Poor fit: Pure lead-gen creators, CRM/funnel-only needs, no existing audience.

Competitor quick reference:
- vs Kajabi: Lower commission, Indian payment stack, no USD pricing friction, vernacular support
- vs Teachable/Thinkific: Community + courses in one, no per-student fees, India-first support
- vs Graphy: More stable platform, no sudden plan shutdowns, dedicated success manager on Enterprise
- vs Mighty Networks/Skool: Branded app option, Indian payment gateway, lower cost for Indian audience
- vs GoHighLevel: Creator-focused not agency, simpler UX, no technical setup needed
- vs Classplus: Better for non-education creators, richer community features, cleaner student UX
- vs WhatsApp/Telegram (informal): Monetization built in, analytics, content gating, professional brand
" --allowedTools "mcp__Calendly__users-get_current_user,mcp__Calendly__meetings-list_events,mcp__Calendly__meetings-list_event_invitees,mcp__Calendly__meetings-get_event_invitee,mcp__Calendly__meetings-get_event,mcp__Slack__slack_send_message,mcp__Slack__slack_search_channels,WebSearch,WebFetch"

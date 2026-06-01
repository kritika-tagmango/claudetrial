#!/bin/bash
# Daily 10:30 AM IST job: fetch today's Calendly calls, enrich each lead, post briefs to #lead-briefs

TODAY=$(date +"%Y-%m-%d")
DATE_DISPLAY=$(date +"%d %B %Y")

claude -p "
Today is $TODAY ($DATE_DISPLAY). You are a pre-call sales intelligence assistant for Kritika Gupta, sales associate at TagMango.

## STEP 1 — FETCH TODAY'S CALENDLY BOOKINGS

Use the Calendly MCP tools to fetch all scheduled events for today ($TODAY). Look through all available Calendly tools (list_events, get_scheduled_events, list_scheduled_events, or similar) to find today's bookings.

Filter out any internal meetings where the invitee email ends in @tagmango.com. Keep only external leads. Sort the remaining calls in chronological order by call time (IST).

If there are NO external calls scheduled today, send a single Slack message to channel C0AV08273PE (#lead-briefs) saying:
'✅ No client calls scheduled for today ($DATE_DISPLAY).'
Then stop.

## STEP 2 — FOR EACH EXTERNAL LEAD, EXTRACT FORM DATA

From each Calendly booking extract as much of the following as is available:
- Full name and email
- WhatsApp number
- Social profile link (Instagram / YouTube / LinkedIn / Twitter)
- Website URL
- What they sell (course / workshop / community / coaching)
- Current platform they use
- Paid community / subscriber strength
- Timeline to move to TagMango
- Expectations from the call
- How they heard about TagMango

## STEP 3 — ENRICH EACH LEAD

For each lead, use web search and web fetch to gather intelligence:
- Social profile link → search the web for follower count, niche, content type, engagement signals, products they sell
- Website URL → fetch the page to understand their products, pricing, and platforms/tools used
- If no social or website link, search '[name] [email domain] creator coach' to find their brand
- Note any competitor platform mentioned for use in Step 4

## STEP 4 — GENERATE A BRIEF FOR EACH LEAD

For each lead produce a brief in this exact format:

---
## 👤 [Full Name] | [Call Time IST]

### 🔹 WHO IS THIS LEAD
2–3 lines on their business, background, scale, and creator journey stage.

### 🔹 PROFILE SNAPSHOT
| Field | Details |
|---|---|
| Name | [name] |
| WhatsApp | [number or N/A] |
| Social Profile | [link or N/A] |
| Niche | [niche] |
| What They Sell | [course/workshop/community/etc] |
| Current Platform | [platform or N/A] |
| Community Size | [number or N/A] |
| Timeline | [timeline] |
| Source | [how they heard about TagMango] |

### 🔹 SOCIAL & WEB INTELLIGENCE
What was found from their profile or website — follower count, engagement, content type, products, platforms used. If nothing found, state 'No public profile found.'

### 🔹 LEAD TEMPERATURE: [🔥 Hot / ☀️ Warm / ❄️ Cold]
One-line reason based on timeline, intent, and community size.

### 🔹 RECOMMENDED SETUP & PLAN
- **Setup:** Freedom or Enterprise — with reason
- **Plan:** Basic / Pro / Advanced / Ultimate — with reason
- **Key Features to Highlight:** List 2–3 TagMango features most relevant to their niche

### 🔹 KEY TALKING POINTS
1. [Specific point tailored to their niche and expectations]
2. [Specific point about their scale or content type]
3. [Specific point addressing their timeline or pain point]

### 🔹 COMPETITOR ANGLE
If they mention a current platform, give the 2–3 strongest TagMango advantages against that specific competitor. If no competitor mentioned, skip this section.

### 🔹 WATCH OUT
Any red flags, misfit signals, or things to be careful about in this call.

---

## STEP 5 — SEND ONE CONSOLIDATED SLACK MESSAGE

Send a SINGLE message to Slack channel C0AV08273PE (#lead-briefs) with:

Header line: '📋 Today's Call Briefs — $DATE_DISPLAY | [X] calls scheduled'

Then each lead brief in chronological order, separated by a blank line.

End the message with a summary table:

## 📊 Summary
| Lead Name | Call Time | Temperature | Recommended Plan | Priority Action |
|---|---|---|---|---|
| [name] | [time] | [🔥/☀️/❄️] | [plan] | [1-line action] |

---

## TAGMANGO PRODUCT CONTEXT (use this when generating briefs):

TagMango is an all-in-one SaaS platform for coaches and creators to host courses, communities, and digital products on their own branded platform.

**Setups:**
- Freedom: ₹1,00,000 one-time — web only
- Enterprise: ₹1,00,000 one-time — branded Android + iOS app, custom website, dedicated success manager

**Plans:**
- Basic: ₹0/month, 10% commission
- Pro: ₹5K/month, 5% commission
- Advanced: ₹15K/month, 2.5% commission
- Ultimate: ₹30K/month, 0% commission

**Key differentiator:** Owned platform vs rented land (WhatsApp, Instagram, LinkedIn). Full control, branding, and monetization.

**Strong fit:** Health/fitness coaches, career/productivity, trading/finance, tech/coding, creators with existing communities.

**Poor fit:** Pure lead-gen creators, CRM/funnel-only needs, no existing audience.

**Competitors to watch for:** Kajabi, Teachable, Thinkific, Graphy, Mighty Networks, GoHighLevel, Skool, Classplus, Tribe.
" --allowedTools "mcp__Calendly__list_scheduled_events,mcp__Calendly__get_scheduled_event,mcp__Calendly__list_event_invitees,mcp__Calendly__get_event_invitee,mcp__Calendly__get_user,mcp__Calendly__list_events,mcp__Calendly__get_event_type,mcp__Calendly__list_user_busy_times,WebSearch,WebFetch,mcp__Slack__slack_send_message,mcp__Slack__slack_search_channels"

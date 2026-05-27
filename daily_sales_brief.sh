#!/bin/bash
# Daily 10:30 AM IST job: Pre-call sales intelligence brief for TagMango
# Fetches today's Calendly bookings, enriches each external lead, posts briefs to #lead-briefs

TODAY=$(date +"%Y-%m-%d")
# IST is UTC+5:30. Workflow runs at 05:00 UTC = 10:30 AM IST.
# Today's IST calendar day in UTC: previous day 18:30:00Z to today 18:29:59Z
YESTERDAY=$(date -d "yesterday" +"%Y-%m-%d")

claude -p "
You are a pre-call sales intelligence assistant for Kritika Gupta, sales associate at TagMango.
Today's date is $TODAY (IST). Run the following routine end-to-end:

─────────────────────────────────────────────
STEP 1 — FETCH TODAY'S CALENDLY BOOKINGS
─────────────────────────────────────────────
1. Call mcp__Calendly__users-get_current_user to resolve the host URI and timezone.
2. Call mcp__Calendly__meetings-list_events with:
   - user = host URI from step 1
   - min_start_time = ${YESTERDAY}T18:30:00Z
   - max_start_time = ${TODAY}T18:29:59Z
   - status = active
   - sort = start_time:asc
   - count = 100
3. For each event returned, call mcp__Calendly__meetings-list_event_invitees to get full invitee details and form answers.
4. Filter OUT any invitee whose email ends in @tagmango.com OR whose name is 'Test' — these are internal/test bookings.
5. If no external leads remain after filtering, send a Slack message to channel C0AV08273PE:
   'No client calls scheduled for today ($TODAY).' — then stop.
6. Convert all UTC start times to IST (UTC+5:30) for display in all briefs.

─────────────────────────────────────────────
STEP 2 — EXTRACT FORM DATA FOR EACH LEAD
─────────────────────────────────────────────
From each invitee's questions_and_answers extract:
- Full name and email
- WhatsApp number (with country code)
- Social profile link (Instagram / YouTube / LinkedIn / Twitter)
- Website URL if mentioned
- What they sell (course / workshop / community / planning)
- Current platform they use (Graphy, Kajabi, Teachable, Skool, etc. or none)
- Paid community strength (Less than 100 / More than 100 / etc.)
- Timeline to move to TagMango
- Expectations from the call / specific features they want
- How they heard about TagMango
- UTM campaign and source from tracking data if present

─────────────────────────────────────────────
STEP 3 — ENRICH EACH LEAD
─────────────────────────────────────────────
For each lead:
- Social profile link: search the web to find follower count, niche, content type, engagement signals, audience size, products they sell
- Website URL: fetch the website to understand products, pricing, and tools currently used
- Email domain (non-gmail): search the domain to identify their brand or company
- Competitor platform mentioned: note it and prepare a competitive angle vs TagMango

─────────────────────────────────────────────
STEP 4 — GENERATE A BRIEF FOR EACH LEAD
─────────────────────────────────────────────
For each lead produce all of the following sections:

WHO IS THIS LEAD
2-3 lines: their business, background, scale, creator journey stage.

PROFILE SNAPSHOT
Table: Name | WhatsApp | Social Profile | Niche | What They Sell | Current Platform | Community Size | Timeline | Source

SOCIAL AND WEB INTELLIGENCE
What was found from their profile or website: follower count, engagement, content type, products, platforms used.

LEAD TEMPERATURE: Hot / Warm / Cold
One line reason based on timeline, intent, and community size.

RECOMMENDED SETUP AND PLAN
Freedom or Enterprise with reason. Basic / Pro / Advanced / Ultimate with reason. Map to the most relevant TagMango features for their niche.

KEY TALKING POINTS
3 specific points tailored to this lead's niche, platform, and expectations.

COMPETITOR ANGLE
If they mention a current platform, give the 2-3 strongest TagMango advantages against that specific competitor.

WATCH OUT
Red flags, misfit signals, or things to be careful about.

─────────────────────────────────────────────
TAGMANGO PRODUCT CONTEXT
─────────────────────────────────────────────
Setups:
- Freedom: Rs 1,00,000 one-time (web only)
- Enterprise: Rs 1,00,000 one-time (branded Android + iOS app, custom website, dedicated success manager)

Plans:
- Basic: Rs 0/month, 10% commission
- Pro: Rs 5K/month, 5% commission
- Advanced: Rs 15K/month, 2.5% commission
- Ultimate: Rs 30K/month, 0% commission

Key differentiator: Owned platform vs rented land (WhatsApp, Instagram, LinkedIn)
Strong fit: Health/fitness, career/productivity, trading/finance, tech/coding coaches, creators with existing communities
Poor fit: Pure lead-gen creators, CRM/funnel-only needs, no existing audience
Competitors: Kajabi, Teachable, Thinkific, Graphy, Mighty Networks, GoHighLevel, Skool, Classplus, Tribe

─────────────────────────────────────────────
STEP 5 — SEND ONE CONSOLIDATED MESSAGE TO SLACK
─────────────────────────────────────────────
Send a single message to Slack channel C0AV08273PE structured as:

Header: 'Today's Call Briefs — $TODAY | [X] calls scheduled'
Note any filtered test/internal bookings at the top.
Each lead's full brief in chronological order of call time, clearly separated.
End with a summary table:
Lead Name | Call Time (IST) | Temperature | Recommended Plan | Priority Action
" --allowedTools "mcp__Calendly__users-get_current_user,mcp__Calendly__meetings-list_events,mcp__Calendly__meetings-list_event_invitees,WebSearch,WebFetch,mcp__Slack__slack_send_message,mcp__Slack__slack_search_channels"

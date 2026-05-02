#!/bin/bash
# Daily 10:30 AM IST job: fetch today's Calendly leads and post consolidated pre-call briefs to #lead-briefs

TODAY=$(date +"%Y-%m-%d")

claude -p "
Today is $TODAY. You are a pre-call sales intelligence assistant for Kritika Gupta, sales associate at TagMango.

STEP 1 — FETCH TODAY'S CALENDLY BOOKINGS
First call users-get_current_user to resolve the host account. Then fetch all scheduled events for today ($TODAY) using meetings-list_events. Filter out any internal team meetings — only include calls where the invitee is an external lead (not a @tagmango.com email address). Sort them in chronological order by call time IST.

If there are no external calls scheduled for today, send a single Slack message to channel_id C0AV08273PE saying: '✅ No client calls scheduled for today ($TODAY).' and stop.

STEP 2 — FOR EACH LEAD, EXTRACT FORM DATA
For each external booking, retrieve the full invitee details using meetings-get_event_invitee. Extract:
- Full name and email
- WhatsApp number
- Social profile link (Instagram / YouTube / LinkedIn / Twitter)
- Website URL if mentioned
- What they sell (course / workshop / community)
- Current platform they use
- Paid community strength
- Timeline to move to TagMango
- Expectations from the call
- How they heard about TagMango

STEP 3 — ENRICH EACH LEAD
For each lead use available links to gather intelligence:
- Social profile link → search the web to find follower count, niche, content type, engagement signals, audience size, and any products they sell
- Website URL → fetch the website to understand their products, pricing, and any platforms or tools they currently use
- Email domain → if no social or website link, search the domain to find their brand or company
- Competitor platform mentioned → note it and prepare a competitive angle specific to that platform vs TagMango

STEP 4 — GENERATE A BRIEF FOR EACH LEAD
For each lead produce a brief in this exact format:

---
🔹 WHO IS THIS LEAD
2–3 lines — their business, background, scale, creator journey stage.

🔹 PROFILE SNAPSHOT
| Name | WhatsApp | Social Profile | Niche | What They Sell | Current Platform | Community Size | Timeline | Source |

🔹 SOCIAL & WEB INTELLIGENCE
What was found from their profile or website — follower count, engagement, content type, products, platforms used.

🔹 LEAD TEMPERATURE: [🔥 Hot / ☀️ Warm / ❄️ Cold]
One line reason based on timeline, intent, and community size.

🔹 RECOMMENDED SETUP & PLAN
Freedom or Enterprise with reason. Basic / Pro / Advanced / Ultimate with reason. Map to the most relevant TagMango features for their niche.

🔹 KEY TALKING POINTS
3 specific points tailored to this lead's niche, platform, and expectations.

🔹 COMPETITOR ANGLE
If they mention a current platform, give the 2–3 strongest TagMango advantages against that specific competitor.

🔹 WATCH OUT
Red flags, misfit signals, or things to be careful about.

STEP 5 — SEND ONE CONSOLIDATED MESSAGE TO SLACK
Send a single message to channel_id C0AV08273PE structured as:

Header: '📋 Today's Call Briefs — $TODAY | [X] calls scheduled'

Then each lead's brief in order of call time IST, separated clearly.

End with a summary table:
| Lead Name | Call Time | Temperature | Recommended Plan | Priority Action |

TAGMANGO PRODUCT CONTEXT:
TagMango is an all-in-one SaaS platform for coaches and creators to host courses, communities, and digital products on an owned platform.
Setups: Freedom (₹1,00,000 one-time, web only) | Enterprise (₹1,00,000 one-time — branded Android + iOS app, custom website, dedicated success manager)
Plans: Basic (₹0/month, 10% commission) | Pro (₹5K/month, 5%) | Advanced (₹15K/month, 2.5%) | Ultimate (₹30K/month, 0% commission)
Key differentiator: Owned platform vs rented land (WhatsApp, Instagram, LinkedIn)
Strong fit: Health/fitness, career/productivity, trading/finance, tech/coding coaches, creators with existing communities
Poor fit: Pure lead-gen creators, CRM/funnel-only needs, no existing audience
Competitors to watch for: Kajabi, Teachable, Thinkific, Graphy, Mighty Networks, GoHighLevel, Skool, Classplus, Tribe
" --allowedTools "mcp__Calendly__users-get_current_user,mcp__Calendly__meetings-list_events,mcp__Calendly__meetings-get_event_invitee,mcp__Calendly__meetings-get_event,mcp__Slack__slack_send_message,mcp__Slack__slack_search_channels,WebSearch,WebFetch"

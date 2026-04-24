#!/bin/bash
# Daily 5:15 PM IST job: fetch today's customer meetings from Granola and post to #lead-briefs

TODAY=$(date +"%Y-%m-%d")

claude -p "
Today is $TODAY. Fetch today's customer meetings from Granola (folder: 'Customer calls', folder_id: 0e604086-b4e7-485c-aaf9-bed9d79c1f4f) using a custom date range of ${TODAY} to ${TODAY}.

For each meeting found, post a separate message to the #lead-briefs Slack channel (channel_id: C0AV08273PE) in this exact format:

*[Meeting Title]* | [Date and Time]

*Participants:* [list participants]

*Overview:* [brief description of what the meeting was about]

*Key Requirements:*
• [requirement 1]
• [requirement 2]

*Pricing Discussed:*
[pricing details if any]

*Next Steps:*
[next steps agreed upon]

Post each meeting as a completely separate Slack message. If no meetings were found for today, post a single message to #lead-briefs saying: 'No customer meetings recorded for $TODAY.'
" --allowedTools "mcp__Granola__list_meetings,mcp__Granola__get_meetings,mcp__Slack__slack_send_message,mcp__Slack__slack_search_channels"

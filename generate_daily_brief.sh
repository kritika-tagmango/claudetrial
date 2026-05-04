#!/bin/bash
# End-of-day job: fetch today's meetings from Granola and generate index.html
# Suggested cron (5:30 PM IST = 12:00 UTC): 0 12 * * * /path/to/generate_daily_brief.sh

TODAY=$(date +"%Y-%m-%d")
DAY_LABEL=$(date +"%A, %B %-d %Y")
OUTPUT="$(cd "$(dirname "$0")" && pwd)/index.html"

echo "Generating daily brief for $TODAY..."

claude -p "
Today is $TODAY ($DAY_LABEL).

Step 1: Fetch today's meetings from Granola.
  Call list_meetings with time_range='custom', custom_start='$TODAY', custom_end='$TODAY'.

Step 2: Get full details for all meetings found.
  Call get_meetings with all meeting IDs batched in a single request (max 10 per call).

Step 3: Write a complete self-contained HTML file to: $OUTPUT

The page must include:
- A sticky dark-navy header showing 'Daily Meeting Brief · $DAY_LABEL', the note-creator's name, and stat counters for total meetings / customer calls / internal meetings.
- A sticky left sidebar (260px) listing all meetings chronologically: time, colored dot, title.
- Each meeting rendered as a card with: colored time badge, title, participants, and the full Granola summary rendered from markdown.
- Color scheme: customer calls = blue (#0369a1), internal meetings = purple (#6d28d9). Classify as internal only when all known participants share the tagmango.com email domain.
- Meetings sorted chronologically by start time.
- A lightweight inline JS markdown renderer that handles ### headings, - bullet lists with 4-space indented sub-bullets, **bold**, and numbered lists.
- For meetings with no summary: show 'Summary not yet available — Granola notes are still being processed.'
- No external CSS, JS, or font dependencies — fully self-contained.

Write the complete HTML to the output file using the Write tool.
" --allowedTools "mcp__Granola__list_meetings,mcp__Granola__get_meetings,Write"

echo "Done. Open: $OUTPUT"

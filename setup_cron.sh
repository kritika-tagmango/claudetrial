#!/bin/bash
# Installs cron jobs for TagMango daily automation scripts.
# Run once on the host machine: bash setup_cron.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Existing: daily meeting brief at 5:15 PM IST = 11:45 UTC
MEETING_JOB="45 11 * * * ${SCRIPT_DIR}/daily_meeting_brief.sh >> ${SCRIPT_DIR}/meeting_brief.log 2>&1"

# New: pre-call sales intelligence at 10:30 AM IST = 05:00 UTC
SALES_JOB="0 5 * * * ${SCRIPT_DIR}/pre_call_sales_intel.sh >> ${SCRIPT_DIR}/pre_call_sales_intel.log 2>&1"

# Add jobs only if not already present
add_cron_job() {
    local job="$1"
    local marker="$2"
    if crontab -l 2>/dev/null | grep -qF "$marker"; then
        echo "Cron job already exists: $marker"
    else
        (crontab -l 2>/dev/null; echo "$job") | crontab -
        echo "Added cron job: $job"
    fi
}

add_cron_job "$MEETING_JOB" "daily_meeting_brief.sh"
add_cron_job "$SALES_JOB"   "pre_call_sales_intel.sh"

echo ""
echo "Current crontab:"
crontab -l

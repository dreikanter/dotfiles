#!/usr/bin/env bash
# Fetch Jira activity for a given date.
# Usage: eod_jira.sh <YYYY-MM-DD>

set -euo pipefail

LOCAL_DATE="${1:?Usage: eod_jira.sh YYYY-MM-DD}"

acli jira --action getIssueList \
  --jql "assignee = currentUser() AND (status in ('In Progress', 'In Review') OR updated >= '$LOCAL_DATE') ORDER BY updated DESC" \
  --columns "key,summary,status" --limit 15 2>/dev/null || true

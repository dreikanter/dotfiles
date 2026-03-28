#!/bin/bash
input=$(cat)
timestamp=$(date '+%Y-%m-%d %H:%M:%S')
session_id=$(echo "$input" | jq -r '.session_id // "unknown"')
reason=$(echo "$input" | jq -r '.reason // "unknown"')
cwd=$(echo "$input" | jq -r '.cwd // "unknown"')

# Foreground log
echo "$timestamp | sid=$session_id | reason=$reason | cwd=$cwd" >> ~/.claude/hooks/session-end.log

# Background summarization (detached so claude CLI exits immediately)
( nohup python3 ~/.claude/hooks/session-end-bg.py "$session_id" "$cwd" "$reason" &>/dev/null & )

exit 0

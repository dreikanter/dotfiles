#!/bin/bash
input=$(cat)
branch=$(git branch --show-current 2>/dev/null)
ctx_pct=$(echo "$input" | jq -r '((.context_window.used_percentage // 0) | floor | tostring) + "%"')
cost_raw=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
cost=$(printf '$%.2f' "$cost_raw")
lines=$(echo "$input" | jq -r '"\u001b[32m+\(.cost.total_lines_added // 0)\u001b[0m \u001b[31m-\(.cost.total_lines_removed // 0)\u001b[0m"')
ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0 | floor')
hours=$((ms / 3600000)); mins=$(((ms % 3600000) / 60000))
if [ "$hours" -gt 0 ]; then duration="${hours}h${mins}m"; else duration="${mins}m"; fi
printf '\033[32m%s\033[0m  \033[34m%s\033[0m  %s  %s  %s  %s\n' "$(pwd)" "$branch" "$ctx_pct" "$cost" "$lines" "$duration"

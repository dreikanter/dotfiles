---
description: "Generate a daily EOD report and save it as a note. Optional arg: date in free format (e.g. 'yesterday', '2d ago', 'last Friday', '2026-03-05')."
---

Generate a daily EOD report and save it as a note.

## Phase 0: Resolve the Target Date

If an argument was provided (e.g. "yesterday", "2d ago", "last Friday", a specific date), resolve it to a concrete calendar date in local timezone using Bash:

```bash
# Examples — adapt based on the argument given:
date -v-1d +%Y-%m-%d          # yesterday
date -v-2d +%Y-%m-%d          # 2d ago
date -v-friday +%Y-%m-%d      # last Friday (use -v-friday if already past it)
```

If no argument was given, use today's local date:

```bash
LOCAL_DATE=$(date +%Y-%m-%d)
```

Also compute the UTC equivalent date (for GitHub/Slack APIs which use UTC internally):

```bash
UTC_DATE=$(TZ=UTC date +%Y-%m-%d)
# If LOCAL_DATE == UTC_DATE, use UTC_DATE for all searches.
# If the local timezone is ahead of UTC (e.g. CET = UTC+1), activity at
# the start of local day (e.g. 00:00–01:00 CET) falls on the previous UTC date.
# Use LOCAL_DATE - 1 day as the lower bound for UTC-based searches to avoid
# missing early-morning local-time activity:
UTC_SEARCH_FROM=$(date -v-1d -j -f "%Y-%m-%d" "$LOCAL_DATE" +%Y-%m-%d 2>/dev/null \
  || date -d "$LOCAL_DATE - 1 day" +%Y-%m-%d)
```

All subsequent steps use `$LOCAL_DATE` as the target date for display, and `$UTC_SEARCH_FROM` as the lower bound for API queries.

## Phase 1: Gather GitHub Activity (Bash)

```bash
LOCAL_DATE=<resolved above>
UTC_SEARCH_FROM=<resolved above>

echo "=== MY PRs ==="
gh pr list --author @me --state all --limit 30 \
  --json number,title,url,updatedAt,state,mergedAt \
  | python3 -c "
import sys, json
target = '$LOCAL_DATE'
prs = json.load(sys.stdin)
for p in prs:
    updated = p['updatedAt'][:10]
    merged  = (p.get('mergedAt') or '')[:10]
    if updated == target or merged == target:
        print(p['state'], p['number'], p['title'], p['url'])
"

echo "=== REVIEWED ==="
gh search prs --reviewed-by @me --updated ">=$UTC_SEARCH_FROM" --limit 20 \
  --json number,title,url,updatedAt \
  | python3 -c "
import sys, json, subprocess
from datetime import datetime, timedelta
target = '\$LOCAL_DATE'
# GitHub timestamps are UTC; convert to local date using system TZ offset before filtering.
try:
    tz_offset_h = int(subprocess.check_output(['date', '+%z']).decode().strip()) // 100
except Exception:
    tz_offset_h = 0
offset = timedelta(hours=tz_offset_h)
prs = json.load(sys.stdin)
for p in prs:
    dt_utc = datetime.fromisoformat(p['updatedAt'].replace('Z', '+00:00')).replace(tzinfo=None)
    local_date = (dt_utc + offset).strftime('%Y-%m-%d')
    if local_date == target:
        print(p['number'], p['title'], p['url'])
"

echo "=== NOTIFICATIONS ==="
gh api "/notifications?all=true&since=${UTC_SEARCH_FROM}T00:00:00Z" --paginate \
  | python3 -c "
import sys, json
ns = json.load(sys.stdin)
for n in ns:
    if n.get('reason') in ('review_requested', 'mention', 'comment'):
        print(n['reason'], n['subject']['title'], n['subject']['url'])
" 2>/dev/null || true
```

## Phase 2: Gather Jira Activity (Bash)

```bash
acli jira --action getIssueList \
  --jql "assignee = currentUser() AND status in ('In Progress', 'In Review') ORDER BY updated DESC" \
  --columns "key,summary,status" --limit 10 2>/dev/null || true

echo "---RECENT---"

acli jira --action getIssueList \
  --jql "assignee = currentUser() AND updated >= startOfDay() ORDER BY updated DESC" \
  --columns "key,summary,status" --limit 10 2>/dev/null || true
```

## Phase 3: Gather Slack Activity

Use `mcp__claude_ai_Slack__slack_search_public_and_private` to find significant discussions from `$LOCAL_DATE`.

**Important**: Do NOT search for `from:me` — that returns your own EOD posts and messages, which are output, not input. Instead, search for discussions and decisions you were involved in or that were significant.

Run these searches (use `after:YYYY-MM-DD` with `$UTC_SEARCH_FROM`):

1. Threads you were mentioned in or replied to: `to:me after:$UTC_SEARCH_FROM` and `to:me during:$LOCAL_DATE`

2. Significant engineering discussions in key channels (decisions, incidents, architectural choices): `in:#eng after:$UTC_SEARCH_FROM has:reaction` or similar high-signal queries

3. If the date is not today, also try: `after:$UTC_SEARCH_FROM before:$LOCAL_DATE_PLUS_1`

From the results, pick only items that are genuinely notable: incidents, architectural decisions, notable questions answered, or significant feedback. Skip routine noise and your own stand-alone EOD posts.

## Phase 4: Synthesize the Report

Produce a concise bullet-point EOD report for **$LOCAL_DATE**.

**Organizational principle**: Group by **activity or theme**, NOT by data source. Do not create separate GitHub/Jira/Slack sections. Instead, weave all sources into a narrative where each bullet describes what you did and why. A single bullet may reference a Jira ticket, a PR, and a Slack thread together if they're part of the same activity.

**Example** (for structure/tone only — actual content will differ):

```
- Created ticket with a plan to evaluate vector search upgrade: [PROJ-123](...). I'd appreciate some [feedback](slack_permalink).
- Epic review:
    - [PROJ-101](...) — corrected AC, scoped to UI only, closed (after [501](...) merge).
    - [PROJ-102](...) — created new ticket for backend wiring (depends on [498](...)).
    - [PROJ-103](...) — drafted status update comment.
- Code reviews: [504](...), [503](...), [499](...)
- Watched [New tool intro](video_link)
- Batching spike is open and needs review: [PROJ-200](...).
- Cycle checkin
```

**Linking rules**:
- PRs: `[504](pr_url)` — number only, no title
- Jira: `[PROJ-123](ticket_url)`
- Slack/video/external links: descriptive anchor text, e.g. `[feedback](slack_permalink)`, `[New tool intro](video_link)`

**Style rules**:
- First person, concise but informative — each bullet tells what was done and gives context
- Use sub-bullets (4-space indent) to group related items under a theme (e.g. epic review, multi-ticket investigation)
- Code reviews go on one line: `Code reviews: [504](...), [503](...)`
- Include non-code activities: meetings, checkins, videos watched, ticket/plan creation, discussions
- Embed links contextually within the narrative — don't isolate Slack/Jira/PR links into their own sections
- Include personal notes or requests when relevant (e.g. "needs review", "I'd appreciate feedback")
- Omit routine noise — only include items that are genuinely worth reporting

## Phase 5: Save as Note

1. Compose the note with this YAML frontmatter:

```yaml
---
slug: eod
tags: [eod, zipline, reports]
---
```

Followed by `EOD report:` and the bullet list.

2. Save it:

```bash
printf '%s' "<note_content>" | ~/.claude/skills/notes-archive/bin/create-note eod
```

3. Report the saved file path.

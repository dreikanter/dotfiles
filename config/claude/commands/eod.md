---
description: "Generate a daily EOD report and save it as a note. Optional arg: date in free format (e.g. 'yesterday', '2d ago', 'last Friday', '2026-03-05')."
---

Generate a daily EOD report and save it as a note.

## Phase 0: Resolve the Target Date

If an argument was provided (e.g. "yesterday", "2d ago", "last Friday", a specific date), resolve it to a concrete calendar date in local timezone using `date`. If no argument was given, use today's local date.

```
# No argument → today; with argument → resolve it, e.g.:
#   "yesterday"        → date -v-1d +%Y-%m-%d
#   "2d ago"           → date -v-2d +%Y-%m-%d
#   "last Friday"      → date -v-Fri +%Y-%m-%d
#   "2026-03-05"       → echo "2026-03-05"
LOCAL_DATE=<resolved date in %Y-%m-%d format>
# For API queries, search from one day before to avoid missing activity near day boundaries:
SEARCH_FROM=$(date -v-1d -j -f "%Y-%m-%d" "$LOCAL_DATE" +%Y-%m-%d)
# Day after LOCAL_DATE (used for Slack date-range queries):
SEARCH_UNTIL=$(date -v+1d -j -f "%Y-%m-%d" "$LOCAL_DATE" +%Y-%m-%d)
```

All subsequent steps use `$LOCAL_DATE` for display, and `$SEARCH_FROM` as the lower bound for API queries.

## Phase 1: Gather Data (GitHub + Jira + Slack + Notes IN PARALLEL)

**CRITICAL**: Phases 1a–1d are independent. Launch ALL FOUR as parallel tool calls in a single message.

### 1a: GitHub Activity (Bash)

```
LOCAL_DATE=<resolved above>
SEARCH_FROM=<resolved above>

echo "=== MY PRs ==="
gh pr list --author @me --state all --limit 30 \
  --json number,title,url,updatedAt,state,mergedAt \
  | python3 -c "
import sys, json
target = '$LOCAL_DATE'
search_from = '$SEARCH_FROM'
prs = json.load(sys.stdin)
for p in prs:
    updated = p['updatedAt'][:10]
    merged  = (p.get('mergedAt') or '')[:10]
    if updated >= search_from and (updated <= target or merged <= target):
        print(p['state'], p['number'], p['title'], p['url'])
"

echo "=== REVIEWED ==="
# Use the events API to get actual review submission timestamps (not PR update dates).
# Paginate up to 3 pages to cover ~1 week of activity.
python3 -c "
import subprocess, json
search_from = '$SEARCH_FROM'
target = '$LOCAL_DATE'
seen = set()
matches = []
for page in range(1, 4):
    result = subprocess.run(
        ['gh', 'api', f'/users/dreikanter/events?per_page=100&page={page}'],
        capture_output=True, text=True)
    if result.returncode != 0: break
    for e in json.loads(result.stdout):
        if e['type'] != 'PullRequestReviewEvent': continue
        reviewed = e['created_at'][:10]
        if reviewed < search_from: break
        if reviewed > target: continue
        repo = e['repo']['name']
        num = e['payload']['pull_request']['number']
        key = (repo, num)
        if key in seen: continue
        seen.add(key)
        matches.append((repo, num))
    else: continue
    break
# Fetch titles for matched PRs
for repo, num in matches:
    result = subprocess.run(
        ['gh', 'api', f'/repos/{repo}/pulls/{num}', '--jq', '.title'],
        capture_output=True, text=True)
    title = result.stdout.strip() if result.returncode == 0 else '(unknown)'
    url = f'https://github.com/{repo}/pull/{num}'
    print(num, title, url)
"
```

### 1b: Jira Activity (Bash)

```
acli jira --action getIssueList \
  --jql "assignee = currentUser() AND (status in ('In Progress', 'In Review') OR updated >= '$LOCAL_DATE') ORDER BY updated DESC" \
  --columns "key,summary,status" --limit 15 2>/dev/null || true
```

### 1c: Slack Activity

Use `mcp__claude_ai_Slack__slack_search_public_and_private` to find significant discussions from `$LOCAL_DATE`.

**Important**: Do NOT search for `from:me` — that returns your own EOD posts, which are output, not input.

Run this search: `to:me after:$SEARCH_FROM before:$SEARCH_UNTIL`

From the results, pick only items that are genuinely notable: incidents, architectural decisions, notable questions answered, or significant feedback. Skip routine noise and your own stand-alone EOD posts.

### 1d: Personal Notes (Bash)

List notes from the target date and read any that look relevant (e.g. todo, note, backlog):

```
notes ls --name $LOCAL_DATE
```

Read matching notes. Include any tasks completed, personal observations, or context that would enrich the EOD report.

## Phase 2: Synthesize the Report

Produce a concise bullet-point EOD report for **$LOCAL_DATE**.

**Deduplicate across sources before writing.** A PR you authored may also appear in reviewed PRs or Slack threads — mention it once, in the most meaningful context.

Group by **activity or theme**, NOT by data source. Weave all sources into a narrative where each bullet describes what you did and why. A single bullet may reference a Jira ticket, a PR, and a Slack thread together if they're part of the same activity.

**Example** (for structure/tone only):

```
EOD Report:

- Created ticket with a plan to evaluate vector search upgrade: [PROJ-123](...). I'd appreciate some [feedback](slack_permalink).
- Reviewed [123](...) and [124](...) for Luis
- Reviewed [125](...) for Becky
- Watched [New tool intro](video_link)
- Batching spike is open and needs review: [PROJ-1000](...).
- Updated backlog note with Q2 capacity estimates
- Cycle checkin
```

**Style**:
- First person, concise but informative
- Links: PRs as `[123](url)`, Jira as `[PROJ-123](url)`, everything else with descriptive anchor text
- Prefer flat lists with no nesting. But use sub-bullets (4-space indent) if it makes sense to group related items under a theme.
- Include non-code activities: meetings, checkins, discussions
- Omit low-value items and routine noise

## Phase 3: Save as Note

Save the report to the new note:

```
cat <<'EOF' | notes new --slug eod --tag eod --tag reports
<note_content>
EOF
```

Report the saved file path.

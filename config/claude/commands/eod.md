---
description: "Generate a daily EOD report and save it as a note. Optional arg: date in free format (e.g. 'yesterday', '2d ago', 'last Friday', '2026-03-05')."
---

Generate a daily EOD report and save it as a note.

## Phase 0: Resolve the Target Date

If an argument was provided (e.g. "yesterday", "2d ago", "last Friday", a specific date), resolve it to a concrete calendar date in local timezone using `date`. If no argument was given, use today's local date.

```
LOCAL_DATE=$(date +%Y-%m-%d)
# For API queries, search from one day before to avoid missing activity near day boundaries:
SEARCH_FROM=$(date -v-1d -j -f "%Y-%m-%d" "$LOCAL_DATE" +%Y-%m-%d)
```

All subsequent steps use `$LOCAL_DATE` for display, and `$SEARCH_FROM` as the lower bound for API queries.

## Phase 1: Gather Data (GitHub + Jira + Slack IN PARALLEL)

**CRITICAL**: Phases 1a, 1b, and 1c are independent. Launch ALL THREE as parallel tool calls in a single message.

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
gh search prs --reviewed-by @me --updated ">=$SEARCH_FROM" --limit 20 \
  --json number,title,url,updatedAt \
  | python3 -c "
import sys, json
search_from = '$SEARCH_FROM'
target = '$LOCAL_DATE'
prs = json.load(sys.stdin)
for p in prs:
    d = p['updatedAt'][:10]
    if search_from <= d <= target:
        print(p['number'], p['title'], p['url'])
"
```

### 1b: Jira Activity (Bash — run in parallel with 1a and 1c)

```
acli jira --action getIssueList \
  --jql "assignee = currentUser() AND (status in ('In Progress', 'In Review') OR updated >= startOfDay()) ORDER BY updated DESC" \
  --columns "key,summary,status" --limit 15 2>/dev/null || true
```

### 1c: Slack Activity (run in parallel with 1a and 1b)

Use `mcp__claude_ai_Slack__slack_search_public_and_private` to find significant discussions from `$LOCAL_DATE`.

**Important**: Do NOT search for `from:me` — that returns your own EOD posts, which are output, not input.

Run this search: `to:me during:$LOCAL_DATE`

From the results, pick only items that are genuinely notable: incidents, architectural decisions, notable questions answered, or significant feedback. Skip routine noise and your own stand-alone EOD posts.

## Phase 2: Synthesize the Report

Produce a concise bullet-point EOD report for **$LOCAL_DATE**.

Group by **activity or theme**, NOT by data source. Weave all sources into a narrative where each bullet describes what you did and why. A single bullet may reference a Jira ticket, a PR, and a Slack thread together if they're part of the same activity.

**Example** (for structure/tone only):

```
- Created ticket with a plan to evaluate vector search upgrade: [PROJ-123](...). I'd appreciate some [feedback](slack_permalink).
- Reviewed [123](...) and [124](...) for Luis
- Reviewed [125](...) for Becky
- Watched [New tool intro](video_link)
- Batching spike is open and needs review: [PROJ-1000](...).
- Cycle checkin
```

**Style**:
- First person, concise but informative
- Links: PRs as `[123](url)`, Jira as `[PROJ-123](url)`, everything else with descriptive anchor text
- Prefer flat lists with no nesting. But use sub-bullets (4-space indent) if it makes sense to group related items under a theme.
- Include non-code activities: meetings, checkins, discussions
- Omit low-value items and routine noise

## Phase 3: Save as Note

Compose the note starting with `EOD report:` followed by the bullet list, then save:

```
echo "<note_content>" | notes new --slug eod --tag eod --tag reports
```

Report the saved file path.

---
description: "Generate a daily EOD report and save it as a note. Optional arg: date in free format (e.g. 'yesterday', '2d ago', 'last Friday', '2026-03-05')."
---

Generate a daily EOD report and save it as a note.

## Phase 0: Resolve the Target Date

If an argument was provided (e.g. "yesterday", "2d ago", "last Friday", a specific date), resolve it to a concrete calendar date in local timezone using `date`. If no argument was given, use today's local date.

```
LOCAL_DATE=<resolved date in %Y-%m-%d format>
SEARCH_FROM=$(date -v-1d -j -f "%Y-%m-%d" "$LOCAL_DATE" +%Y-%m-%d)
SEARCH_UNTIL=$(date -v+1d -j -f "%Y-%m-%d" "$LOCAL_DATE" +%Y-%m-%d)
```

## Phase 1: Gather Data (IN PARALLEL)

**CRITICAL**: Phases 1a-1d are independent. Launch ALL FOUR as parallel tool calls in a single message.

### 1a: GitHub Activity (Bash)

```
${CLAUDE_SKILL_DIR}/eod_github.sh $LOCAL_DATE
```

### 1b: Jira Activity (Bash)

```
${CLAUDE_SKILL_DIR}/eod_jira.sh $LOCAL_DATE
```

### 1c: Slack Activity

Use `mcp__claude_ai_Slack__slack_search_public_and_private` to find significant discussions from `$LOCAL_DATE`.

**Important**: Do NOT search for `from:me` — that returns your own EOD posts, which are output, not input.

Run this search: `to:me after:$SEARCH_FROM before:$SEARCH_UNTIL`

From the results, pick only items that are genuinely notable: incidents, architectural decisions, notable questions answered, or significant feedback. Skip routine noise and your own stand-alone EOD posts.

### 1d: Personal Notes (Bash)

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
- Links: PRs as `[#123](https://github.com/retailzipline/zipline-app/pull/123)`, Jira as `[ZIP-123](https://retailzipline.atlassian.net/browse/ZIP-123)`. Always link every Jira ID mentioned in the text. Use descriptive anchor text for everything else.
- People: Use real first names from the GitHub script output (resolved via `gh api`). Never guess or override names — trust the API output.
- Prefer flat lists with no nesting. But use sub-bullets (4-space indent) if it makes sense to group related items under a theme.
- Include non-code activities: meetings, checkins, discussions
- Omit low-value items and routine noise

## Phase 3: Save as Note

```
cat <<'EOF' | notes new --slug eod --tag eod --tag reports
<note_content>
EOF
```

Report the saved file path.

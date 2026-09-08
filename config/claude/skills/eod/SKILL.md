---
name: eod
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

Resolve `SKILL_DIR` to the directory holding this `SKILL.md`. Claude Code exposes
it as `CLAUDE_SKILL_DIR`; other harnesses show the absolute skill path at
discovery time. Do not assume the variable exists.

## Phase 1: Gather Data (IN PARALLEL)

**CRITICAL**: Phases 1a-1e are independent. Launch all collectors as parallel tool calls in a single message.

### 1a: GitHub Activity (Bash)

```
$SKILL_DIR/eod_github.sh $LOCAL_DATE
```

### 1b: Jira Activity (Bash)

```
$SKILL_DIR/eod_jira.sh $LOCAL_DATE
```

### 1c: Slack Activity

Use the connected Slack search tool (in Claude Code: `mcp__claude_ai_Slack__slack_search_public_and_private`) to find significant discussions from `$LOCAL_DATE`.

**Important**: Do NOT search for `from:me` — that returns your own EOD posts, which are output, not input.

Run this search: `to:me after:$SEARCH_FROM before:$SEARCH_UNTIL`

From the results, pick only items that are genuinely notable: incidents, architectural decisions, notable questions answered, or significant feedback. Skip routine noise and your own stand-alone EOD posts.

### 1d: Personal Notes (Bash)

```
notes ls --name $LOCAL_DATE
```

Read matching notes. Include any tasks completed, personal observations, or context that would enrich the EOD report.

### 1e: Agent Sessions (Bash)

```
python3 $SKILL_DIR/eod_codex.py $LOCAL_DATE
python3 $SKILL_DIR/eod_claude.py $LOCAL_DATE
```

Both collectors read local session storage in read-only mode and print the
requests and outcomes of primary sessions from the target date. Subagents,
sidechains, and generated messages are filtered out already. A missing store or
no matching sessions is an empty source, not an error.

Use the output as work context. Summarize only completed work, decisions,
reviews, planning, or other meaningful activity. Ignore the session generating
this report, workflow chatter, and proposed actions that never happened.

## Phase 2: Synthesize the Report

Produce a concise bullet-point EOD report for **$LOCAL_DATE**.

**Deduplicate across sources before writing.** A PR you authored may also appear in reviewed PRs, Slack threads, and agent sessions. Mention it once, in the most meaningful context.

Group by **activity or theme**, NOT by data source. Weave all sources into a narrative where each bullet describes what you did and why. A single bullet may reference a Jira ticket, a PR, and a Slack thread together if they're part of the same activity.

**Example** (for structure/tone only):

```
EOD Report:

- Created ticket with a plan to evaluate vector search upgrade: [PROJ-123](...). I'd appreciate some [feedback](slack_permalink).
- Reviewed [123](...) for Luis
- Reviewed [124](...) for Luis
- Reviewed [125](...) for Becky
- Watched [New tool intro](video_link)
- Batching spike is open and needs review: [PROJ-1000](...).
- Updated backlog note with Q2 capacity estimates
- Cycle checkin
```

**Style**:
- First person, concise but informative
- Links: PRs as `[123](https://github.com/retailzipline/zipline-app/pull/123)` (no `#` prefix in the anchor text), Jira as `[ZIP-123](https://zipline.atlassian.net/browse/ZIP-123)`. Always link every Jira ID mentioned in the text. Use descriptive anchor text for everything else.
- One PR or Jira ticket per bullet line. Do not combine multiple PRs or tickets into one bullet (a bullet's PR may still reference its own Jira ticket).
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

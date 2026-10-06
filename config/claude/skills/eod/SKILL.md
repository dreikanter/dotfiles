---
name: eod
description: Generate an EOD report for today or requested dates and save it as a note.
---

## Phase 0: Resolve the Target Dates

Resolve requested dates in the local timezone using `date`; default to today. For multiple dates, gather data for each date and combine it into one report.

```
LOCAL_DATE=<resolved date in %Y-%m-%d format>
SEARCH_FROM=$(date -v-1d -j -f "%Y-%m-%d" "$LOCAL_DATE" +%Y-%m-%d)
SEARCH_UNTIL=$(date -v+1d -j -f "%Y-%m-%d" "$LOCAL_DATE" +%Y-%m-%d)
```

Resolve `SKILL_DIR` to the directory holding this `SKILL.md`. Claude Code exposes
it as `CLAUDE_SKILL_DIR`; other harnesses show the absolute skill path at
discovery time. Do not assume the variable exists.

## Phase 1: Gather Data

Run the independent collectors in phases 1a-1e in parallel for each target date.

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

Do not search for `from:me`; it returns your own EOD posts.

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

Start with exactly `EOD Report:` on its own plain-text line, followed by a blank line. The title is fixed: no date, date range, markup, or heading syntax, including for reports covering multiple dates.

Write concise bullets starting with a past-tense action, such as "Completed", "Reviewed", or "Clarified". Do not use "I", "my", or "we". Keep the report suitable for Slack: describe outcomes and decisions at a high level, without implementation details or test counts. Deduplicate across sources and group by activity or theme. Include meaningful non-code work such as meetings, discussions, and planning; omit routine noise and uncompleted proposals.

For reviews, use "Reviewed <PR link> for <first name>, <very short description>". Example: "Reviewed [123](https://github.com/retailzipline/zipline-app/pull/123) for <first name>, sign-in page updates."

- Never use em dashes; semicolons are allowed.
- Link PRs as `[123](https://github.com/retailzipline/zipline-app/pull/123)` without a `#` prefix. Link every Jira ID as `[ZIP-123](https://zipline.atlassian.net/browse/ZIP-123)`. Use descriptive anchors for other links.
- Keep separate PRs or tickets on separate bullet lines; a PR may include its own Jira ticket and related discussion.
- Use first names from the GitHub script's API output; never guess.
- Prefer flat bullets; use sub-bullets with four-space indentation only when grouping helps.

## Phase 3: Save as Note

```
cat <<'EOF' | notes new --slug eod --tag eod --tag reports
<note_content>
EOF
```

Report the saved file path.

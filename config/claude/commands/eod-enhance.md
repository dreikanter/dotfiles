---
description: "Enhance an EOD draft note with Jira/GitHub details. Optional arg: note UID (e.g. 20260520_10008) or note:// reference. Defaults to today's eod-slug note."
---

Enhance an EOD report draft in place. Pull additional details from Jira and GitHub as warranted; do not create a new note.

## Phase 0: Resolve the Target Note

If an argument was provided, treat it as a note UID (e.g. `20260520_10008`) or `note://UID` reference. Extract the UID, then locate the file under `$NOTES_PATH` (or `/Users/alex/Library/CloudStorage/Dropbox/Notes`) — the year/month directory is encoded in the UID prefix:

```
UID=<extracted from arg, e.g. 20260520_10008>
YEAR=${UID:0:4}
MONTH=${UID:4:2}
NOTE_PATH=$(ls "$NOTES_PATH/$YEAR/$MONTH/${UID}"*.md 2>/dev/null | head -1)
```

If no argument was given, pick today's note with the `eod` slug:

```
notes ls --slug eod --today
```

Pick the most recent matching note and read it. Extract `$LOCAL_DATE` from the UID (first 8 chars → `YYYY-MM-DD`).

If no eod-slug note exists for today, stop and tell the user to create the draft first (or invoke `/eod`).

## Phase 1: Gather Data (IN PARALLEL)

Launch all three as parallel tool calls in a single message.

### 1a: GitHub Activity

```
cd /Users/alex/zipline/zipline-app && /Users/alex/.claude/skills/eod/eod_github.sh $LOCAL_DATE
```

### 1b: Jira Activity

```
acli jira workitem search \
  --jql "assignee = currentUser() AND (status in ('In Progress', 'In Review') OR updated >= '$LOCAL_DATE') ORDER BY updated DESC" \
  --fields "key,summary,status" --limit 15 2>/dev/null || true
```

### 1c: Same-Day Context Notes

Read any other notes from the same date (todo, claude-sessions, plain notes) that might enrich the report:

```
ls /Users/alex/Library/CloudStorage/Dropbox/Notes/$YEAR/$MONTH/${UID:0:8}*.md
```

Read the todo note and any claude-sessions note for the same date.

## Phase 2: Format the Report

Rewrite the note in place with these strict rules:

- **Title line is exactly `EOD Report:`** — no date in parens, no trailing date.
- **Frontmatter**: keep whatever is already there. If the file is empty or has no frontmatter, use only `slug: eod`.
- **Flat bullet list — no nesting.** Even if multiple PRs share a theme, list them as separate top-level bullets rather than indenting under a parent bullet.
- **Target length: 4-7 top-level bullets.** Match the May 12–15 style, not the heavier multi-paragraph style.
- **Links**:
    - PRs: `[#NUMBER](https://github.com/retailzipline/zipline-app/pull/NUMBER)`
    - Jira: `[ZIP-NNNN](https://zipline.atlassian.net/browse/ZIP-NNNN)` — always linked, never bare.
    - Other URLs: descriptive anchor text.
- **People**: real first names from `gh api` output. Never guess or override.
- **Grouping**: by activity/theme, not by data source. Deduplicate — each PR/ticket appears once, in its most meaningful context.
- **Voice**: first person, concise but informative.
- **Include**: meetings, reviews, deploys, notable Slack discussions, non-code work when it matters.
- **Omit**: routine noise, your own stand-alone EOD Slack posts.

Preserve any context already in the draft that the tooling output doesn't reflect — the user may have written reminders the API can't see.

## Phase 3: Save

Overwrite the existing note file in place. Report the saved path.

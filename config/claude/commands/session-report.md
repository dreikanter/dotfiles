---
description: Append a one-line session summary to today's report note. Creates the note if it doesn't exist.
---

Append a one-line summary of the current session to today's report note.

## Step 1: Summarize the current session

Produce a **single line** answering "What was done?" in this session.

**Format rules**:

- One line only. No bullet points, no headers.
- First person, past tense.
- If the session involved a PR, reference it: `[#123](https://github.com/org/repo/pull/123)`
- If the session involved a Jira ticket, reference it: `[PROJ-123](https://retailzipline.atlassian.net/browse/PROJ-123)`
- Always link references to their original URLs using Markdown syntax.
- **Never assume people's names.** If a name is needed (e.g., PR author for a review), use `gh api` to fetch it. Trust only API output.

**Examples**:

```
Reviewed [#456](https://github.com/org/repo/pull/456) for Alice
Opened [PROJ-789](https://retailzipline.atlassian.net/browse/PROJ-789) — migrate auth tokens to secure storage
Closed [PROJ-101](https://retailzipline.atlassian.net/browse/PROJ-101)
Drafted Q2 capacity planning spec
```

## Step 2: Ensure today's report note exists

Check whether today's report note already exists:

```bash
notes latest --slug report 2>/dev/null | grep -q "$(date +%Y%m%d)" && echo "EXISTS" || echo "MISSING"
```

If `MISSING`, create a new report note for today:

```bash
echo "" | notes new --slug report --title "Session Report" --tag reports
```

## Step 3: Append to today's report note

```bash
echo "- <summary line>" | notes append --slug report
```

Report what was appended.

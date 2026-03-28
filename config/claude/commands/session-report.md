---
description: Append a one-line session summary to today's report note. Creates the note if it doesn't exist.
---

Append a one-line summary of the current session to today's report note.

## Step 1: Summarize the current session

Produce a **single line** answering "What was done?" in this session.

**Format rules**:

- One line only. No bullet points, no headers.
- First person, past tense.
- If the session involved a PR, reference it: `[123](https://github.com/org/repo/pull/123)`
- If the session involved a Jira ticket, reference it: `[PROJ-123](https://retailzipline.atlassian.net/browse/PROJ-123)`
- Always link references to their original URLs using Markdown syntax.
- **Never assume or guess people's names from their GitHub username.** When you need a person's real name (e.g., PR author for a review), resolve it as follows:
  1. Look for `config/engineers.yml` in the current project directory. If the file exists, read it (do not assume its format) and look up the GitHub username. Use the first name if found.
  2. If the file does not exist or the username is not in it, use `gh api /users/{username}` to fetch the profile name.
  3. Only use a name you resolved from one of these two sources.

**Examples**:

```
Reviewed [456](https://github.com/org/repo/pull/456) for Alice

Opened [PROJ-789](https://retailzipline.atlassian.net/browse/PROJ-789) — Migrate auth tokens to secure storage

Closed [PROJ-101](https://retailzipline.atlassian.net/browse/PROJ-101) — Implement parallel data processing ([458](https://github.com/org/repo/pull/456))

Drafted Q2 capacity planning spec
```

## Step 2: Ensure today's report note exists

Check whether today's report note already exists:

```bash
notes ls --slug report --today 2>/dev/null | grep -q report && echo "EXISTS" || echo "MISSING"
```

If `MISSING`, create a new report note for today:

```bash
echo "EOD Report:\n" | notes new --slug report --title "EOD Report" --tag reports
```

## Step 3: Append to today's report note

```bash
echo "- <summary line>" | notes append --slug report
```

Report what was appended.

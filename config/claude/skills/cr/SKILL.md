---
name: cr
description: Code-review a GitHub PR against Jira ticket(s) and produce a self-contained HTML report with structured, color-coded findings. Use when the user asks to review a PR (e.g. "review this PR", "/cr <url>", "cr <url> PROJ-123").
---

# cr

Run the `cr` script bundled with this skill. It gathers PR data
(`prdump` + `gh pr diff`), Jira context (`jiradump`), reads modified
files, asks Claude for a JSON-structured review, and renders an HTML
report with color-coded findings, click-to-select, addressed
checkboxes, type filters, j/k navigation, and `localStorage`
persistence.

## Usage

```
${CLAUDE_SKILL_DIR}/cr <pr_url> [JIRA-ID|JIRA_URL ...]
```

Arguments may be in any order. The PR URL is required. Jira IDs/URLs
are optional; additional Jira references found in the PR description
are also gathered automatically.

## Steps

1. Pass the user-supplied arguments through to the script verbatim — do
   not pre-process them.
2. The script prints the absolute path of the generated HTML file on
   stdout. Open it: `open <path>` on macOS.
3. Report the path to the user. Do not print HTML contents in chat.
4. If the script exits non-zero, surface its stderr verbatim and stop.

## Configuration

- `CR_MODEL` — model passed to `claude --print`. Defaults to
  `claude-opus-4-7`. Override for cheaper/faster runs.

## Diagnostics

If the script reports a missing dependency:

- `gh` missing: `brew install gh`, then `gh auth login`.
- `prdump` missing: provided by this dotfiles repo (`bin/prdump`).
- `claude` missing: install Claude Code.
- `jiradump` missing: optional; only required when Jira refs are given.

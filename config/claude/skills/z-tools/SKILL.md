---
name: z-tools
description: Review GitHub pull requests with Jira context using local `prdump`, `jiradump`, and `gh` tools. Use when a user asks for a PR review by providing a PR URL and Jira ticket URL(s), or when a PR description references Jira IDs/URLs that should be pulled for additional context.
---

# Z Tools

## Overview

Review PRs by combining `prdump` output, Jira ticket context via `jiradump`, and a branch diff from `gh pr diff` using only PR/Jira URLs.

## Tools

- `prdump <pr_url>`: Dumps PR title, branch, description, discussion, reviews, and inline review comments.
- `prcopy <pr_url>`: Copies `prdump` output to clipboard.
- `jiradump <jira_url_or_key>`: Dumps Jira ticket details and comments.
- `jiracopy <jira_url_or_key>`: Copies `jiradump` output to clipboard.
- `gh pr diff <pr_url>`: Prints the PR diff using the PR URL.

## Workflow

1. Run `prdump <pr_url>` and capture the PR title, description, discussion, reviews, and inline review comments.
1. Extract Jira IDs/URLs from the user-provided Jira URLs and the PR description (e.g., `ABC-123` or Jira URLs).
1. De-duplicate the Jira list and run `jiradump` for each relevant ticket to gather context.
1. Fetch the diff with `gh pr diff <pr_url>` (PR URL only; do not require repo/branch inputs).
1. Review the PR using:
   - Jira context (intent, acceptance criteria, risks).
   - Diff (logic changes, tests, edge cases, regressions).
   - PR discussion and review comments (address concerns or missing follow-ups).

## Diagnostics

If `prdump` or `jiradump` report missing tools or auth, provide brief setup instructions:

1. `gh` missing: `brew install gh`, then `gh auth login`.
1. `jira` missing: `brew install jira-cli`, then `jira init`.
1. Auth errors (e.g., “not logged in”): run the appropriate login/init command.

## Output Expectations

Summarize findings, highlight risks, and list actionable feedback with references to relevant diff sections or Jira requirements. Keep the response concise and review-focused.

---
description: "Review a GitHub PR against Jira ticket acceptance criteria. Args: URLs and Jira IDs in any order."
---

You are performing a structured code review of a GitHub pull request, cross-referenced against Jira ticket(s) for scope and acceptance criteria.

## Input

Parse all arguments provided after `/cr` in any order. Classify each argument:

- **GitHub PR URL**: matches `github.com/.*/pull/\d+`. Exactly one is required.
- **Jira ticket URL**: matches your Jira domain (e.g., `atlassian.net/browse/PROJ-123`). Treat as a Jira reference.
- **Jira ticket ID**: matches the pattern `[A-Z][A-Z0-9]+-\d+` (e.g., `PROJ-123`, `ABC-42`). Treat as a Jira reference.

Collect all Jira references from the arguments. Additional Jira IDs/URLs found in the PR description will also be gathered later in Phase 2.

If no GitHub PR URL is found among the arguments, ask the user for it before proceeding.

## Phase 1: Gather PR Data

Run these commands using Bash and capture their full output:

1. `prdump <pr_url>` — captures PR title, branch, description, discussion, reviews, and inline comments.
2. `gh pr diff <pr_url>` — captures the full diff. Extract the list of changed file paths from the diff headers (`diff --git a/... b/...` lines) — no separate API call needed.

From the PR URL, extract `{owner}`, `{repo}`, and `{pr_number}`. These are used to construct per-finding source links that open the PR diff with the relevant lines selected.

The link format is:
`https://github.com/{owner}/{repo}/pull/{pr_number}/changes#diff-{sha256hex}R{line}`

For line ranges: `#diff-{sha256hex}R{start}-R{end}`

`{sha256hex}` is the SHA-256 hash of the file path (no leading slash). Compute it with:
```bash
echo -n "{filepath}" | shasum -a 256
```

Compute hashes for all changed files upfront in a single Bash call so they are ready when writing findings.

## Phase 2: Gather Jira Context (Task sub-agent)

Launch a **Task sub-agent** (subagent_type: Bash) to fetch Jira context in parallel with Phase 3:

- Collect all Jira IDs/URLs from: the user-provided arguments AND the PR description body.
- De-duplicate the list.
- Run `jiradump <jira_id_or_url>` for each ticket.
- Return the combined output: ticket summaries, descriptions, acceptance criteria, and comments.

If no Jira tickets are found anywhere, note this in the review and skip scope assessment.

## Phase 3: Read Modified Files (Task sub-agent)

Launch a **Task sub-agent** (subagent_type: general-purpose) in parallel with Phase 2:

- Take the list of changed file paths from Phase 1.
- For each file, use the Read tool to read the full current file content from the local working directory (not just the diff hunks). This provides surrounding context for understanding the changes.
- If a file was deleted in the PR, note it but skip reading.
- If a file does not exist locally (new file only in the PR branch), note it and rely on the diff for context.
- Return all file contents with their paths.

## Phase 4: Analyze and Produce Review

With all data gathered, analyze the PR holistically and produce a structured review in Markdown. Use the following exact format:

```markdown
## Summary of Changes

<2-4 sentence summary of what this PR does, the approach taken, and key design decisions.>

## Scope Assessment

### In-Scope (maps to ticket requirements)
- <Change or file that directly addresses a specific acceptance criterion. Reference the criterion.>

### Out-of-Scope (does not map to ticket requirements)
- <Change that is not covered by any acceptance criterion. Flag whether it is a reasonable adjacent change or a concern.>

### Missing from Ticket
- <Any acceptance criterion from the Jira ticket NOT addressed by this PR.>

## Findings

<Each finding uses this block format. Repeat for every issue, bug, and question.>

`path:line`
[View source](https://github.com/{owner}/{repo}/pull/{pr_number}/changes#diff-{sha256hex}R{line})
**{type}**

Description. Lead with the problem statement. State the fix if obvious.

---

<If none, write "None.">
```

## Finding Types

Every finding must be tagged with one of:

- `nitpick` — cosmetic or style concern; non-blocking
- `suggestion` — meaningful improvement worth acting on
- `bug` — potential defect, edge case, or regression risk
- `question` — unclear intent; needs author input
- `blocker` — must be resolved before merge

## Guidelines

- Be specific: reference file paths and line numbers from the diff.
- Be proportional: small PRs get concise reviews, large PRs get thorough reviews.
- Write descriptions in plain declarative sentences. Lead with the problem statement. No hedge language ("might", "could potentially"), no praise. State the fix directly if it is obvious.
- If the PR has existing review comments or discussion, acknowledge addressed feedback and flag unresolved threads.
- Do not repeat what the diff already makes obvious. Focus on what a reviewer might miss.
- The output must be valid Markdown suitable for pasting as a GitHub PR review comment.

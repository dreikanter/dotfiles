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

From the PR URL, extract `{owner}`, `{repo}`, and `{pr_number}`. These are used to construct per-finding source links that open the PR diff with the relevant lines selected.

**Run `prdump` and `gh pr diff` as parallel Bash calls** (they are independent):

1. `prdump <pr_url>` — captures PR title, branch, description, discussion, reviews, and inline comments.
2. `gh pr diff <pr_url>` — captures the full diff. Extract the list of changed file paths from the diff headers (`diff --git a/... b/...` lines) — no separate API call needed.

Once both return, compute SHA-256 hashes for all changed files in a single Bash call:

```bash
echo -n "{filepath}" | shasum -a 256
```

The link format for per-finding source links is:
`https://github.com/{owner}/{repo}/pull/{pr_number}/changes#diff-{sha256hex}R{line}`

For line ranges: `#diff-{sha256hex}R{start}-R{end}`

## Phase 2: Gather Jira Context + Read Modified Files (parallel sub-agents)

**Launch BOTH sub-agents in a single message** so they run concurrently:

### 2a: Jira Context (Agent, subagent_type: general-purpose)

- Collect all Jira IDs/URLs from: the user-provided arguments AND the PR description body.
- De-duplicate the list.
- Run `jiradump <jira_id_or_url>` for each ticket.
- Return the combined output: ticket summaries, descriptions, acceptance criteria, and comments.

If no Jira tickets are found anywhere, note this in the review and skip scope assessment.

### 2b: Read Modified Files (Agent, subagent_type: general-purpose)

- Take the list of changed file paths from Phase 1.
- For each file, use the Read tool to read the full current file content from the local working directory (not just the diff hunks). This provides surrounding context for understanding the changes.
- If a file was deleted in the PR, note it but skip reading.
- If a file does not exist locally (new file only in the PR branch), note it and rely on the diff for context.
- If the PR branch is not checked out locally, note this limitation and rely on the diff for context where local files diverge.
- Return all file contents with their paths.

## Review Principles

### Architecture First

Before reviewing individual lines, assess the overall approach:

- Is this the right pattern? Are there existing conventions in the codebase that should be used instead?
- Does the controller/service/engine split make sense?
- Are module/package boundaries respected — no inappropriate cross-boundary dependencies?

If the architecture is wrong, focus the review on that. Do not polish tactical details on code that needs a fundamentally different approach.

### Do No Harm

- **Never suggest broken code.** Before proposing any code snippet, verify it is syntactically valid in the target language. If unsure, describe the idea in prose instead.
- **Understand the domain before flagging issues.** Do not apply generic patterns (race conditions, naming conventions, fragile coupling) without understanding WHY the code is written that way. If code looks intentional, consider that the author understands their domain.
- **Do not flag hypothetical problems that cannot happen.** "What if X happens?" is only useful if X can actually happen given the architecture. Trace actual code paths before raising concerns.

## Phase 3: Analyze and Produce Review

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

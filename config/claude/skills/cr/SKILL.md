---
name: cr
description: "Review a GitHub PR against Jira ticket acceptance criteria and publish the report as a Claude Artifact. Args: PR URL and Jira IDs in any order."
---

Perform a structured code review of a GitHub pull request, cross-referenced against Jira ticket(s) for scope and acceptance criteria.

## Input

Parse all arguments in any order. Classify each argument:

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

```
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
- Read the full content of each file from the PR branch, not the local working copy, which may be on a different branch: `git show origin/<pr_branch>:<path>` (fetch the branch first if needed).
- If a file was deleted in the PR, note it but skip reading.
- If a file is new in the PR, read it from the branch the same way.
- Also ask the agent for the specific supporting facts the diff depends on: whether the variables/helpers/aliases it uses actually resolve, what the callers and consumers of a changed value are, and what the tests pin. These are what turn a guess into a finding.
- Return all file contents plus a direct answer per question, with `file:line` references.

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

## Phase 3: Publish the Review

With all data gathered, analyze the PR holistically and publish the review as a Claude Artifact.

Delivery rules:

- **Do not load the `artifact-design` skill.** The page style is fixed by `theme.css` in this skill's directory. Read that file and inline it verbatim inside a `<style>` block, and emit the Google Fonts `<link>` its header names. Do not add, rename, or override any rule in it.
- Build the markup against the contract documented at the top of `theme.css`. Those class names are the only ones styled.
- Write the page to a file in the session scratchpad directory, then publish it with the `Artifact` tool. The file is only the transport the tool requires; it is not a deliverable.
- Never print the HTML, the review body, or the scratchpad path in chat. The only chat output is the artifact URL, plus at most two sentences naming the most severe findings.
- Re-reviewing the same PR in one session: call `Artifact` again with the same file path, which keeps the URL. From a later session, pass the prior URL as `url`.
- Artifact metadata:
  - `<title>`: `PR #{pr_number} Review` (keep it stable across redeploys).
  - `description`: one sentence naming the PR title.
  - `favicon`: `🔍`.
- The file is wrapped in a `<!doctype html>` skeleton at publish time. Write page content only, no `<html>`, `<head>`, or `<body>` tags of your own.

### Page structure

Follow the `theme.css` contract, with this content in this order. Omit any section with nothing in it.

1. **Masthead** — eyebrow (`PR #N · TICKET-N · branch`, PR and ticket linked), the PR title as `h1`, a `.lede` of at most two lines on what the PR does, and a `.tally` of counts (findings, blockers, missing requirements, files).
2. **Findings** (`h2`) — one `article.finding` each, ordered most severe first, `.num` carrying the rank. If there are none, say so in a `.note` instead.
   - `.rail`: the rank and the severity label, using the matching `type-*` class.
   - `.where`: `path:line`, linked to the PR diff anchor from Phase 1.
   - `.finding-body`: a `p.claim` stating the problem in one line, then prose in Humanized Writing Style (below), then a `pre` snippet where code is clearer than words.
3. **Scope** (`h2`) — issues only. Never list or confirm requirements the PR covers. Use an `h3` per group, each followed by a `ul.plain`:
   - *Missing from ticket* — an acceptance criterion, or a requirement stated in a ticket comment, that this PR does not address.
   - *Out of scope* — a change that maps to no requirement. Say whether it is reasonable adjacent work or a concern.
4. **Addressed since the last round** (`h2`, in a `.note`) — only when the PR has prior review threads. Say which were taken and which are still open, and treat an unresolved thread you can confirm as a finding of its own.

## Finding Types

Every finding must be tagged with one of:

- `nitpick` — cosmetic or style concern; non-blocking
- `suggestion` — meaningful improvement worth acting on
- `bug` — potential defect, edge case, or regression risk
- `question` — unclear intent; needs author input
- `blocker` — must be resolved before merge

## Guidelines

- Be specific: reference file paths and line numbers from the PR branch.
- Be proportional: small PRs get concise reviews, large PRs get thorough reviews.
- Each finding must be self-contained and fully explained at the depth of an "explain this" answer: include the mechanism trace, a concrete triggering example or mutation, and the fix. Do not ship terse one-liners that require a follow-up question to understand. The non-obvious *why* is the deliverable.
- If the PR has existing review comments or discussion, acknowledge addressed feedback and flag unresolved threads.
- Requirements can live in ticket comments, not just the description. Read them as acceptance criteria.
- When the PR description no longer matches the diff, that is a finding — a reviewer trusting the body will miss what changed.
- Do not repeat what the diff already makes obvious. Focus on what a reviewer might miss.

### Writing Style (Humanized)

Write every finding's prose in this voice:

- Answer first, then the why.
- Short sentences. One idea per sentence.
- Short paragraphs, 2-4 sentences each. Never a wall of text.
- Avoid nested clauses.
- No excess. Hemingway in non-fiction.
- No hedge language ("might", "could potentially"), no praise, no filler, no recap.
- Prefer a concrete example, mutation, or code snippet over an abstract description.
- State the fix directly. Show valid code when obvious; never suggest broken code.

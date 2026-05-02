# code-review

## Description

Run a one-shot Claude Code subagent review of the current branch or PR. Use when the user asks to review code with a Claude Code subagent or requests an independent code review.

## Instructions

- From the repository root, run exactly one Claude Code review command.
- Use model `claude-opus-4-7` with a 600 second timeout.
- If the command fails, report its stdout/stderr; do not try alternate invocations.
- Do not allow the reviewer to edit files.

## Command

Set `REVIEW_TARGET` to the review scope, then run:

```sh
REVIEW_TARGET='current branch changes against main'
printf '%s' "Review ${REVIEW_TARGET}. Do not modify files." | \
  timeout 600 claude -p \
    --model claude-opus-4-7 \
    --agent reviewer \
    --agents '{"reviewer":{"description":"Code review subagent","prompt":"You are a senior code reviewer. Review the requested target. Focus on correctness, safety, edge cases, tests, docs, and maintainability. Do not edit files. Return findings with severity and file/line references, followed by a brief summary."}}' \
    --allowedTools 'Bash(git diff:*),Bash(git status:*),Bash(go test:*),Bash(make lint:*),Read,Grep'
```

For a specific PR, use:

```sh
REVIEW_TARGET='PR #<number> / current branch changes against main'
```

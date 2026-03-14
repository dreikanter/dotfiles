---
name: prdump
description: Dump GitHub PR details (title, branch, description, discussion, reviews, inline comments) using the local `prdump` CLI tool. Use when a user wants to inspect or review a PR by URL.
---

# prdump

Run `prdump <pr_url>` to dump PR title, branch, description, discussion, reviews, and inline review comments.

## Diagnostics

If `prdump` reports missing tools or auth:

1. `gh` missing: `brew install gh`, then `gh auth login`.
1. Auth errors: run `gh auth login`.

---
name: jiradump
description: Dump Jira ticket details and comments using the local `jiradump` CLI tool. Use when a user wants to inspect a Jira ticket by URL or key (e.g., ABC-123).
---

# jiradump

Run `jiradump <jira_url_or_key>` to dump Jira ticket details and comments.

## Diagnostics

If `jiradump` reports missing tools or auth:

1. `jira` missing: `brew install jira-cli`, then `jira init`.
1. Auth errors: run `jira init`.

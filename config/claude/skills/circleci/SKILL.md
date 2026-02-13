---
name: circleci
description: Fetch CircleCI CI status, test failures, and job logs for a GitHub PR. Use when checking if a PR passed CI, fetching test errors, or investigating CI failures.
---

# CircleCI

## Overview

Fetch CircleCI pipeline status, failed job details, and test failure messages for a GitHub pull request using `gh` and the CircleCI API v2.

## Prerequisites

- `gh` CLI authenticated with the target GitHub org
- `CIRCLECI_TOKEN` defined in `~/.zshenv` (a `CCIPAT_...` personal API token)
- `jq` for JSON parsing

## Authentication

The `$CIRCLECI_TOKEN` env var often does not expand in the Claude Code shell. To work around this, read the token directly from `~/.zshenv` before making API calls:

```bash
CIRCLECI_TOKEN=$(grep CIRCLECI_TOKEN ~/.zshenv | sed 's/.*=//')
```

Run this once at the start, then use `$CIRCLECI_TOKEN` in subsequent curl commands within the same Bash invocation.

All curl commands below assume `CIRCLECI_TOKEN` has been set this way. Always use `/usr/bin/curl` (absolute path) to avoid PATH issues.

## Workflow

When the user provides a GitHub PR URL or number (with repo context), follow these steps:

### 1. Get CI check status

```bash
gh pr checks <pr_url> 2>&1 | head -60
```

Output is tab-separated: `check_name \t status \t duration \t url`. Look for checks with `fail` status. The URL contains the CircleCI workflow ID.

### 2. Extract workflow ID from failed checks

Parse the workflow ID from the CircleCI URL in step 1 — it's the UUID in `.../workflows/{workflow_id}`.

If the `gh pr checks` output doesn't clearly show the workflow URL, use the GitHub API:

```bash
gh api repos/{owner}/{repo}/commits/$(gh pr view <pr_number> --repo {owner}/{repo} --json headRefOid --jq .headRefOid)/check-runs \
  --jq '.check_runs[] | select(.conclusion == "failure") | {name: .name, details_url: .details_url}'
```

### 3. List failed jobs in the workflow

```bash
CIRCLECI_TOKEN=$(grep CIRCLECI_TOKEN ~/.zshenv | sed 's/.*=//') && \
/usr/bin/curl -s -H "Circle-Token: $CIRCLECI_TOKEN" \
  "https://circleci.com/api/v2/workflow/{workflow_id}/job" | \
  jq -r '.items[] | select(.status == "failed") | "\(.name): \(.job_number)"'
```

### 4. Get test failures from a failed job

```bash
CIRCLECI_TOKEN=$(grep CIRCLECI_TOKEN ~/.zshenv | sed 's/.*=//') && \
/usr/bin/curl -s -H "Circle-Token: $CIRCLECI_TOKEN" \
  "https://circleci.com/api/v2/project/{project_slug}/{job_number}/tests" | \
  jq -r '.items[] | select(.result == "failure") | "FAILED: \(.classname) - \(.name)\nMessage: \(.message)\n"'
```

**Project slug format**: `gh/{org}/{repo}`

### 5. (Optional) Check if a failure is a known flaky test

```bash
CIRCLECI_TOKEN=$(grep CIRCLECI_TOKEN ~/.zshenv | sed 's/.*=//') && \
/usr/bin/curl -s -H "Circle-Token: $CIRCLECI_TOKEN" \
  "https://circleci.com/api/v2/insights/{project_slug}/flaky-tests" | \
  jq -r '.flaky_tests[] | select(.test_name | test("{search_pattern}")) | "\(.test_name) - \(.times_flaked) flakes"'
```

## API Reference

| Purpose                    | Endpoint                                                        |
|----------------------------|-----------------------------------------------------------------|
| List jobs in a workflow    | `GET https://circleci.com/api/v2/workflow/{workflow_id}/job`    |
| Get test results for a job | `GET https://circleci.com/api/v2/project/{slug}/{job_number}/tests` |
| Get flaky test insights    | `GET https://circleci.com/api/v2/insights/{slug}/flaky-tests`  |

**Auth**: `Circle-Token` HTTP header.

**Project slug**: `gh/{org}/{repo}`

## Common Use Cases

**"Did the PR pass CI?"**
Run step 1. Report pass/fail status for each check.

**"What tests failed?"**
Run steps 1-4. Report the failed test names and failure messages.

**"Is this a flaky test?"**
Run step 5 after identifying the failing test name.

## Notes

- When reporting results, include the test class, test name, and failure message.
- If no test failures are found but the job failed, the failure may be a build/setup error rather than a test failure — report the job name and status.

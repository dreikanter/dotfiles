---
description: "Aggregate a prioritized daily todo from Slack, Jira, GitHub PRs, and notifications. Optional arg: notes UID referencing a context note (e.g. '20260309_9174')."
---

Aggregate an easy-to-read flat prioritized todo list for today, based on the most recent context from all available sources.

## Phase 0: Todo Note + Context Note

### 0a. Ensure today's todo note exists

Create today's todo note if missing (idempotent — skips if already exists, carries over pending tasks from previous day):

```bash
notes new-todo
```

Then read it:

```bash
notes read todo
```

Parse all task lines (`- [ ]`, `- [+]`, `- [>]`).

**Skip completed (`[+]`) and moved (`[>]`) tasks** — only process open (`[ ]`) tasks.

Categorize each open task:

- **Work tasks**: anything related to code, PRs, Jira, reviews, deploys, team syncs, EOD, or work-related activities. The `[daily]` tag indicates a recurring work task.
- **Personal tasks**: items tagged `[Private]` or clearly unrelated to work (billing, personal errands, etc.).

**Include all tasks** — both work and personal. Personal tasks are classified with `category: personal` in the YAML.

### 0c. Enrich todo note tasks

**Work tasks** — enrich with external context:

1. **Extract references** — find GitHub PR URLs, Jira ticket IDs, note UIDs (e.g. `[20260313_9235]`) in the task text.
2. **Fetch context for GitHub URLs** — for each PR URL found, run:
   ```bash
   gh pr view <number> --repo <owner>/<repo> --json title,author,url,state,reviewDecision,additions,deletions,isDraft
   ```
3. **Fetch context for note UIDs** — for each `[YYYYMMDD_NNNN]` reference, run:
   ```bash
   notes read <UID>
   ```
4. **Keep the task concise** — use fetched context to write a better `context` field in the YAML, but do not bloat the task. Match the shape/length of other todo items.

**Personal tasks** — only enrich if the context/origin is clearly understood (e.g. a URL in the task text). Otherwise lift the task text as-is into `title` and leave `context` empty or minimal.

All tasks from the todo note use `source: todo_note` in the YAML. Work tasks use `category: work` (default, can be omitted). Personal tasks use `category: personal`.

### 0d. Context Note (Optional)

If an argument was provided, it is a **notes UID** (e.g. `20260309_9174`) referencing a context note with background information for today's work.

Find and read the note:

```bash
notes read $ARGUMENT
```

Use its content as additional context when prioritizing and synthesizing the todo list. Do NOT include raw context note content in the output — use it to inform priorities and fill gaps.

If no argument was provided, skip this step.

## Phase 1: Gather Sources (in parallel where possible)

### 1a. Jira Inbox

```bash
jira-inbox 2>/dev/null
```

If `jira-inbox` fails, fall back to `acli`:

```bash
acli jira --action getIssueList \
  --jql "assignee = currentUser() AND resolution = Unresolved ORDER BY priority ASC, updated DESC" \
  --columns "key,issuetype,summary,status,priority" --limit 30 2>/dev/null
```

### 1b. GitHub PRs and Notifications

Run these in parallel:

```bash
# Notifications
gh api notifications --paginate 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for n in data[:50]:
    s = n.get('subject', {})
    print(f\"{n.get('reason')} | {s.get('type')} | {s.get('title')} | {n.get('repository',{}).get('full_name','')} | {n.get('updated_at','')} | {s.get('url','')}\")
"

# My open PRs
gh pr list --author @me --state open --limit 15 --json number,title,url,reviewDecision,updatedAt
```

For each PR that is `review_requested` from me or authored by me: fetch title, author, review status, size, and any recent comments directed at me.

### 1c. Slack

Use Slack MCP tools to search:

1. `to:me after:<yesterday>` — DMs and mentions
2. `<@MY_SLACK_ID> after:<2 days ago>` — broader mentions
3. Read the project team channel (`#project-team`) for today's messages
4. Read the team channel (`#team-updates`) for recent updates
5. Read `#dev-general` for today's messages
6. Check `from:me` for the most recent EOD to understand yesterday's state

Extract: action items, follow-up requests, decisions, announcements affecting my work.

### 1d. GitHub PR Details and Attention Signals

For each PR found in 1b that needs my attention (review requested, or my PR with new comments), fetch:

```bash
gh pr view <number> --repo <repo> --json title,author,url,createdAt,additions,deletions,reviewDecision,reviews,isDraft,reviewRequests
```

For PRs with active discussions, also fetch review comments:

```bash
gh api repos/<owner>/<repo>/pulls/<number>/comments --paginate
gh api repos/<owner>/<repo>/issues/<number>/comments
```

**For every PR-related todo item, classify its attention signal** by checking the following (in priority order):

| Signal tag      | Condition | Priority boost |
|-----------------|-----------|----------------|
| `SOLE_REVIEWER` | I am the only requested reviewer (no other reviewers, or all others have already submitted) | Highest — no one else can unblock this |
| `AUTHOR_REPLIED`| The PR author posted a new comment replying to one of my review comments (indicates they addressed feedback and are waiting for re-review) | High — someone is directly waiting on my response |
| `MENTIONED`     | I was @-mentioned in a PR comment or review body | High — explicit request for my attention |
| `DIRECT_REQUEST`| I was individually requested as reviewer (not via a team/group request) but other reviewers are also requested | Medium-high — personal request but not sole blocker |
| `TEAM_REQUEST`  | I was requested via a team (e.g. `project/team-name`) rather than individually | Medium — shared responsibility |
| `SUBSCRIBED`    | I'm getting notifications because I'm watching/subscribed, but no direct request | Low — informational only |

**How to determine signal:**

1. Check `reviewRequests` in the PR JSON — if it contains only my username, it's `SOLE_REVIEWER`. If it contains my username among others, it's `DIRECT_REQUEST`. If it contains a team slug, it's `TEAM_REQUEST`.
2. Check notification reason from `gh api notifications`: `review_requested` → personal request, `team_mention` → team request, `mention` → mentioned, `comment` → could be author reply.
3. For `AUTHOR_REPLIED`: in the review comments, check if the PR author posted a reply to a comment thread where I was the original reviewer. Look for `in_reply_to_id` pointing at my comments, or author comments timestamped after my last review.

**Display the signal tag** in the todo item summary line as a short badge, e.g.:

```html
<details open>
<summary><strong>1. Review <a href="...">#123</a></strong> · <code>SOLE_REVIEWER</code> — jdoe: Fix tooltip alignment on dashboard widgets</summary>
```

If multiple signals apply, show the highest-priority one.

## Phase 2: Synthesize the Todo List

Produce a **flat prioritized list** of tasks. Each item should be a collapsible `<details open>` block (expanded by default).

### Prioritization rules (highest to lowest)

1. **Blocking teammates** — reviews where I am `SOLE_REVIEWER`
2. **Author replied to my feedback** — `AUTHOR_REPLIED` signals re-review needed
3. **Direct mentions** — `MENTIONED` in PR comments
4. **Direct review requests** — `DIRECT_REQUEST` where I'm one of several reviewers
5. **Active feedback on my PRs** — comments needing response
6. **My PRs ready to merge** — approved, just need the merge button
7. **Team review requests** — `TEAM_REQUEST`, shared responsibility
8. **Manual tasks from todo note** — work tasks from the daily todo note (non-recurring, non-`[daily]`)
9. **In-progress Jira work** — tickets I'm actively working on
10. **Awareness items** — things happening that affect my work (upgrades, team decisions)
11. **Recurring tasks** — EOD report, team sync prep, etc. (includes `[daily]` items from todo note)
12. **Personal tasks** — `category: personal` items from the todo note

### Format for each item

```html
<details open>
<summary><strong>N. Action verb <a href="URL">#NUMBER</a></strong> · <code>SIGNAL_TAG</code> — Author/context: Short title</summary>

1-2 sentences of context. What specifically needs doing and why.
</details>
```

The `· <code>SIGNAL_TAG</code>` part is only included for GitHub PR items that have a classified signal. Non-PR items (Jira work, recurring tasks, etc.) omit it.

For items originating from the todo note, add a `· <code>TODO</code>` badge in the summary line (same position as `SIGNAL_TAG`). If a todo note task also has a PR signal (e.g., a task with a PR URL that maps to a `SOLE_REVIEWER` signal), show the PR signal instead — it's more informative. The `TODO` badge is only for tasks that have no other signal.

### Linking rules

- PRs: `[#NUMBER](url)` or inline `<a href="url">#NUMBER</a>` in summary
- Jira: `[PROJECT-NNNN](https://org.atlassian.net/browse/PROJECT-NNNN)`
- Keep descriptions concise — this is a scannable list, not a report

### Username mapping rules

For each todo item, collect **every GitHub username** mentioned anywhere in its `title`, `context`, or `blocking` fields — regardless of whether the username appears with an `@` prefix or not. Map each to its GitHub profile URL in a `usernames_map` dictionary on the todo item. Keys are bare usernames (no `@` prefix):

```yaml
usernames_map:
  "jdoe": "https://github.com/jdoe"
  "asmith": "https://github.com/asmith"
```

Include **all** GitHub usernames found in the todo text — PR authors, reviewers, people mentioned in discussion, blocking users, etc. When unsure whether a name is a GitHub username, include it if it was obtained from GitHub data (PR author, reviewer, commenter).

## Phase 3: Processed Sources Reference

After the todo list, add a **collapsed** `<details>` section (NOT expanded) listing every resource you processed:

- The todo note (UID and count of work/personal/completed tasks)
- Every PR you read (with linked number and short description)
- Every Slack channel/DM/search you read
- Every Jira ticket from the inbox
- GitHub notifications summary

Format: one resource per line, `<linked id> — short description`.

## Phase 4: Known/Expected Tasks

Always include these recurring items at the bottom of the todo list (lower priority unless sources reveal urgency):

- Do code reviews
- Follow up on active PR feedback
- Prep status update for team sync
- Write EOD report for Slack

These may be merged with source-derived items when they overlap (e.g., specific PRs needing review replace the generic "do code reviews" item).

**`[daily]` tasks from the todo note** (e.g., `[daily] Github notifications`, `[daily] Jira`) map naturally to these recurring items or to source-gathering activities. Merge them — do not create duplicate entries. Use `source: todo_note` for merged items where the todo note was the origin.

## Phase 5: Save as YAML

Generate a UUID7 for each todo item:

```bash
python3 -c "import uuid; print(uuid.uuid7())"
```

Save the todo list as a YAML file:

```bash
DAILIES_PATH="${DAILIES_PATH:-$HOME/dailies}"
mkdir -p "$DAILIES_PATH"
```

Filename: `YYYYMMDD.yml` (today's date).

### YAML structure

```yaml
date: "2026-03-11"
generated_at: "<ISO 8601 timestamp>"
sources_processed: <total count of items scanned>

todos:
  - id: "019cdd2f-b695-7741-9dcb-aaefae886552"  # UUID7, sortable
    position: 1
    action: review  # enum: review, respond, merge, write, awareness, prep
    title: "Fix tooltip alignment on dashboard widgets"
    priority: high  # enum: high, medium, low
    signal: sole_reviewer  # enum: sole_reviewer, author_replied, mentioned, direct_request, team_request, subscribed (omit for non-PR items)
    source: todo_note  # enum: github, jira, slack, todo_note, recurring (omit or use most specific source when task comes from multiple)
    category: personal  # enum: work, personal (omit for work — it's the default)
    blocking: ["jdoe"]  # GitHub usernames of people waiting on me
    refs:
      pr: "https://github.com/org/project/pull/1"
      jira: "https://org.atlassian.net/browse/PROJECT-NNNN"  # if applicable
    refs_map:
      "#1": "https://github.com/org/project/pull/1"
      "PROJECT-NNNN": "https://org.atlassian.net/browse/PROJECT-NNNN"
    usernames_map:
      "jdoe": "https://github.com/jdoe"
    context: "Small bugfix (22+/1-), no reviews yet. jdoe is blocked."

  - id: "019cdd2f-c8a2-7123-abcd-1234567890ab"
    position: 2
    action: respond
    signal: author_replied
    # ... etc

sources:
  todo_note:
    uid: "20260311_9200"
    work_tasks: 8
    personal_tasks: 1
    completed_tasks: 3
  github_prs:
    - ref: "#123"
      url: "https://github.com/org/project/pull/123"
      description: "Fix tooltip alignment on dashboard widgets"
    # ...
  github_notifications:
    total_scanned: 50
    review_requested: 5
    subscribed: 20
  slack_channels:
    - channel: "#project-team"
      description: "Team EOD reports"
    # ...
  jira_tickets:
    - ref: "PROJECT-1234"
      url: "https://org.atlassian.net/browse/PROJECT-1234"
      description: "Example ticket description"
    # ...
```

Write the YAML file:

```bash
cat > "$DAILIES_PATH/$(date +%Y%m%d).yml" << 'YAML_EOF'
<generated yaml content>
YAML_EOF
```

Report the saved file path at the end of the response.

---
name: honeybadger
description: Use when investigating production/staging errors, exceptions, crashes, or faults reported in Honeybadger — fetching recent errors, backtraces, occurrence counts, or affected users for a project.
---

# Honeybadger

Read errors from Honeybadger via the `hb` CLI. The auth token lives in fnox, so
prefix every command with `fnox exec --`.

## Critical gotchas

- Use **`hb`** (`/opt/homebrew/bin/hb`), NOT `honeybadger`. The `honeybadger`
  gem CLI only *reports* data; `hb` has the Data API for *reading* faults.
- Reading faults needs `HONEYBADGER_AUTH_TOKEN`, provided by fnox. Always wrap:
  `fnox exec -- hb ...`. Run from a dir where fnox resolves the token
  (user's global config at `~/.config/fnox/config.toml` provides it).
- `--project-id` is required for fault commands. Resolve it from the current
  repo (see below) rather than hardcoding one.

## Pick the project from the current repo

Before running fault commands, infer which Honeybadger project the user means
from the repo you're in:

1. Get the repo name: `basename -s .git "$(git remote get-url origin)"`
   (e.g. `github.com/username/example` → `example`). Fall back to the working
   dir name if there's no remote.
2. Run `fnox exec -- hb projects list` — the first `ID` column holds the
   `--project-id` value. Match the repo name against the `NAME` column
   **case-insensitively**.
3. On a match, use that project's ID for all fault commands and tell the user
   which project you focused on (e.g. "Using the *example* project").
4. No match → ask which project, or list them for the user to choose.

## Quick reference

```bash
fnox exec -- hb projects list                                   # list projects + fault counts
fnox exec -- hb faults list --project-id <ID> --limit 15        # recent faults (default order=recent)
fnox exec -- hb faults list --project-id <ID> --order frequent
fnox exec -- hb faults list --project-id <ID> -q "NoMethodError"    # search/filter
fnox exec -- hb faults get      --project-id <ID> --id <FAULT_ID>   # detail + backtrace
fnox exec -- hb faults notices  --project-id <ID> --id <FAULT_ID>   # individual occurrences
fnox exec -- hb faults counts   --project-id <ID>
fnox exec -- hb faults affected-users --project-id <ID> --id <FAULT_ID>
```

- `--limit` max is 25; `--order` is `recent` (default) or `frequent`.
- `recent` orders by last-seen regardless of status, so the list mixes
  resolved and unresolved faults. There's no server-side resolved filter —
  check the `RESOLVED` column (✓) and filter client-side if you only want
  open problems.
- The table view truncates long/multi-line messages and wraps badly. Use
  `-o json` whenever a message is cut off or you need the full backtrace.
- When reporting a fault to the user, link it to its web page. The `-o json`
  output carries a `url` field; otherwise build it as
  `https://app.honeybadger.io/projects/<ID>/faults/<FAULT_ID>`.
- Other namespaces: `hb deployments`, `hb insights`, `hb uptime`, `hb check-ins`.
  Run `fnox exec -- hb <cmd> --help` for flags.

## Typical workflow

1. Resolve the project ID from the current repo (see above).
2. `fnox exec -- hb faults list --project-id <id>` to see what's broken.
3. Grab the unresolved fault IDs and `hb faults get --id <id>` for the backtrace.
4. Cross-reference the backtrace with the codebase to find the root cause.
5. When citing a fault, include its Honeybadger web URL (see above) so the
   user can open the report.

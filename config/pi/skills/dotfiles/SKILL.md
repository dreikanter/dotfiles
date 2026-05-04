---
name: dotfiles
description: Conventions for working with the user's personal dotfiles repo at ~/.dotfiles. Use when modifying tracked config files (anything mapped in ~/.dotfiles/dotfiles.json) or when the user mentions "dotfiles".
---

# Dotfiles

Personal dotfiles repo at `~/.dotfiles`, managed by the [`dotfiles-cli`](https://github.com/dreikanter/dotfiles-cli) tool (`dotfiles` on `$PATH`).

For commands and flags, run `dotfiles --help` (and `dotfiles <command> --help`) — it's self-describing.

## Mapping

`~/.dotfiles/dotfiles.json` maps source paths in `$HOME` to mirrored paths under `~/.dotfiles/config/<tool>/`. Entries are files or directories (trailing `/` = directory, tracked recursively). Adding a file inside an already-mapped directory needs no manifest change — just `save`.

## Workflow when editing a tracked file

1. Edit the live file in `$HOME` (not the copy under `~/.dotfiles/config/`).
2. `dotfiles status` — confirm drift.
3. `dotfiles save` — local → repo. Prefer scoping with `--tool` / `--file` (see `dotfiles save --help`) to avoid touching unrelated drift.
4. In `~/.dotfiles`, branch and make an **atomic commit**.

## Conventions (not in `--help`)

- **Atomic commits, never `git add -A`.** An unscoped `save` syncs every drifted tracked file, so `git status` may surface unrelated changes the user made earlier. Stage only the files for the current logical change — one change per commit.
- If `apply` vs `save` direction is ambiguous (unexpected drift, possible data loss), ask the user which side is authoritative.
- **No commit attribution.** No `Co-authored-by`, no agent signatures.

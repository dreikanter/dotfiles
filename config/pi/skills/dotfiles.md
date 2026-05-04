---
name: dotfiles
description: Conventions and gotchas for working with the user's personal dotfiles repo at ~/.dotfiles. Use when modifying tracked config files (anything mapped in ~/.dotfiles/dotfiles.json, e.g. files under ~/.pi/, ~/.config/, ~/.claude/, etc.) or when the user mentions "dotfiles".
---

# Dotfiles

Personal dotfiles repo at `~/.dotfiles`, managed by a small Ruby CLI at `~/.dotfiles/bin/dotfiles`. Run `~/.dotfiles/bin/dotfiles --help` for the full command surface; it's self-describing. This skill covers the *conventions* that aren't obvious from `--help`.

## Mapping

`~/.dotfiles/dotfiles.json` maps source paths in `$HOME` to mirrored paths under `~/.dotfiles/config/<tool>/`. Entries can be individual files or directories (e.g. `~/.pi/agent/extensions/` mirrors the whole tree). Adding a new file inside an already-mapped directory needs no config change — just `save`.

## Workflow when editing a tracked file

1. Edit the live file in `$HOME` (e.g. `~/.pi/agent/extensions/foo.ts`), not the copy under `~/.dotfiles/config/`.
2. `~/.dotfiles/bin/dotfiles status` — confirm the file shows as `dotfile missing` or `local changes`.
3. `~/.dotfiles/bin/dotfiles save` — copies live → repo.
4. In `~/.dotfiles`, create a branch and make an **atomic commit** (one logical change per commit).

## Gotchas

- **`save` is repo-wide.** It syncs *every* tracked file with local drift, not just the one you edited. After `save`, `git status` may show unrelated files (e.g. `config/ghostty/config`, `bin/review`) that the user changed earlier. **Never `git add -A`.** Stage only the file(s) for the current task.
- **Branch prefixes** (same as the user's other repos): `feature/` for new functionality, `internal/` for refactors / dep upgrades, `bugfix/` for fixes.
- **No commit attribution.** Don't add "Co-authored-by" or agent signatures.
- **Atomic commits.** One file or one logical change per commit; don't bundle unrelated drift just because `save` surfaced it.
- **Direction matters.** `save` = local → repo. `apply` (alias `load`) = repo → local. Don't confuse them when reconciling drift; ask the user which side is authoritative if unsure.

## Quick reference

```bash
~/.dotfiles/bin/dotfiles status   # what's in sync / drifted / missing
~/.dotfiles/bin/dotfiles save     # local -> repo
~/.dotfiles/bin/dotfiles apply    # repo -> local
~/.dotfiles/bin/dotfiles config   # show resolved mapping
```

---
name: dotfiles
description: Use when working with the user's dotfiles managed by the `dotfiles` CLI — saving live config into the tracked repository, installing tracked files to live paths, inspecting tracked-file status, or scaffolding a new dotfiles repo.
---

# dotfiles

Use the `dotfiles` CLI to manage a checked-in mirror of local configuration
files. A JSON manifest (`dotfiles.json`) declares which files to track; the
CLI copies (not symlinks) them between the live filesystem and the
git-managed mirror.

## Manifest

`dotfiles.json` maps a tool name to a list of paths. A trailing `/` marks an
entry as a directory tracked recursively; without it the entry is a single
file. The trailing slash is the sole signal for directory-ness and is not
inferred from disk: a directory declared without the slash, or a file declared
with one, is reported as an error.

Example:

```json
{
  "git":   ["~/.gitconfig", "~/.gitignore_global"],
  "shell": ["~/.zshrc"],
  "nvim":  ["~/.config/nvim/"]
}
```

Use `dotfiles track` / `dotfiles untrack` to modify the manifest rather than
editing it by hand.

## Global flags

| Flag | Description |
|------|-------------|
| `--root` | Dotfiles repository root (default: `$DOTFILES_ROOT` or `~/.dotfiles`) |
| `--config` | Manifest file path (default: `<root>/dotfiles.json` or `$DOTFILES_CONFIG`) |
| `--json` | Emit a single JSON object on stdout; non-zero exit on failure |

## Commands

Run `dotfiles <command> --help` for each command's full flag list and JSON
output shape.

### init

Scaffold a new dotfiles repository.

```sh
dotfiles init
dotfiles init --root ~/my-dotfiles
dotfiles init --force --dry-run
```

Creates the repository directory, writes an empty `dotfiles.json` and a
`README.md`, and runs `git init`. Refuses to overwrite existing files unless
`--force` is passed.

JSON output shape:

```json
{
  "root":    "/abs/path",
  "dryRun":  false,
  "force":   false,
  "actions": [{"action": "create|overwrite|skip|git-init|git-skip", "path": "...", "message": "..."}]
}
```

### save

Copy tracked files from their live paths into the repository mirror (live → saved).

```sh
dotfiles save
dotfiles save --tool git
dotfiles save --tool git --file ~/.gitconfig --file ~/.gitignore_global
dotfiles save --dry-run
```

Use `--tool` to restrict to one tool; combine with `--file` for individual
files. `--prune` removes saved files no longer in the manifest.

JSON output shape:

```json
{
  "direction": "save",
  "dryRun": false,
  "copied": 2,
  "unchanged": 1,
  "removed": 0,
  "errors": 0,
  "filter": {"tool": "git", "files": ["~/.gitconfig"]},
  "actions": [{"action": "copy|unchanged|prune|error", "from": "...", "to": "...", "path": "...", "message": "..."}]
}
```

### install

Copy saved repository files to their live paths (saved → live).

```sh
dotfiles install
dotfiles install --tool git
dotfiles install --tool git --file ~/.gitconfig
dotfiles install --dry-run
```

Accepts the same `--tool`, `--file`, `--prune`, and `--dry-run` flags as `save`.

JSON output shape: same as `save` with `"direction": "install"`.

### status

Show files whose live and saved copies disagree.

```sh
dotfiles status
dotfiles status --tool git
dotfiles status --json
```

Plain text lists only out-of-sync entries; `--json` includes every tracked
file.

JSON output shape:

```json
{
  "entries": [{"tool": "...", "live": "...", "saved": "...", "state": "modified|missing-live|missing-saved|in-sync|error", "error": "..."}],
  "summary": {"total": 4, "unsynced": 1}
}
```

### config

Print the resolved root, manifest path, and full live-to-saved mapping.

```sh
dotfiles config
dotfiles config --tool git
dotfiles config --json
```

JSON output shape:

```json
{
  "root":    "/abs/dotfiles",
  "config":  "/abs/dotfiles/dotfiles.json",
  "entries": [{"tool": "git", "live": "/home/user/.gitconfig", "saved": "/abs/dotfiles/git/.gitconfig"}]
}
```

### track

Add a path to `dotfiles.json` under a tool name.

```sh
dotfiles track ~/.gitconfig --tool git
dotfiles track ~/.config/nvim/ --tool nvim
dotfiles track ~/.gitconfig --tool git --dry-run
```

The path must exist on disk; directories are detected automatically and
recorded with a trailing slash. Run `dotfiles save` afterwards to copy the
file into the repository for the first time.

JSON output shape:

```json
{"action": "tracked|already-tracked", "tool": "git", "path": "~/.gitconfig"}
```

### untrack

Remove a path from `dotfiles.json`.

```sh
dotfiles untrack ~/.gitconfig --tool git
dotfiles untrack ~/.config/nvim/ --tool nvim --purge
dotfiles untrack ~/.gitconfig --tool git --dry-run
```

The live file is left untouched. Pass `--purge` to also delete the saved copy
from the repository.

JSON output shape:

```json
{"action": "untracked", "tool": "git", "path": "~/.gitconfig", "purged": "/abs/saved"}
```

### skill

Print or install this skill document.

```sh
dotfiles skill                              # print to stdout
dotfiles skill --json                       # emit JSON {name, description, body}
dotfiles skill --install                    # write to all detected agent locations
dotfiles skill --install --agent=claude     # write to the Claude Code location
dotfiles skill --install --force            # overwrite a diverging copy
dotfiles skill --install --dry-run          # preview actions without writing
```

Supported `--agent` values:

- `claude` → `~/.claude/skills/dotfiles/SKILL.md`

Without `--agent`, auto-detects installed agents. Without `--force`, refuses to
overwrite a file whose content differs from the current skill.

## JSON output and errors

Every command accepts `--json` to emit a single JSON object on stdout. Plain
text and JSON are never mixed in the same invocation. The exact per-command
JSON shape is documented in `dotfiles <command> --help`.

On any failure, `--json` mode emits the standard error envelope and the
process exits non-zero:

    { "error": { "message": "..." } }

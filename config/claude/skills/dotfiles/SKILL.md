---
name: dotfiles
description: Use when working with the user's dotfiles managed by the `dotfiles` CLI — saving live config into the tracked repository, installing tracked files to live paths, inspecting tracked-file status, or scaffolding a new dotfiles repo.
---

# dotfiles

`dotfiles` manages a checked-in mirror of the user's local config files. A
JSON manifest (`dotfiles.json`) declares which files to track; the CLI
copies (not symlinks) them between the live filesystem and the
git-managed mirror.

## Global flags

| Flag | Description |
|------|-------------|
| `--config` | manifest file path (default: <root>/dotfiles.json or $DOTFILES_CONFIG) |
| `--json` | emit a single JSON object on stdout (non-zero exit on failure) |
| `--root` | dotfiles repository root (default: $DOTFILES_ROOT or ~/.dotfiles) |

## Commands

Each command's full flag list and JSON output shape is documented in
`dotfiles <command> --help`.

| Command | Purpose |
|---------|---------|
| `config` | Print the resolved live-to-saved mapping |
| `init` | Scaffold a fresh dotfiles repository |
| `install` | Copy tracked files to their live paths |
| `save` | Copy tracked files into the dotfiles repository |
| `skill` | Print an agent-installable skill describing this CLI |
| `status` | Show the tracked files status |

## Manifest

`dotfiles.json` maps a tool name to a list of paths. A trailing `/`
marks an entry as a directory whose contents are tracked recursively;
without a trailing slash the entry is a single file. Paths support `~`
and absolute paths.

Example:

    {
      "git":   ["~/.gitconfig", "~/.gitignore_global"],
      "shell": ["~/.zshrc"],
      "nvim":  ["~/.config/nvim/"]
    }

The manifest is the single source of truth: the CLI never touches
files outside the resolved live-to-saved mapping.

## JSON output and errors

Every command accepts `--json` to emit a single JSON object on stdout.
Plain text and JSON are never mixed in the same invocation. The exact
per-command JSON shape is documented in `dotfiles <command> --help`.

On any failure, `--json` mode emits the standard error envelope and
the process exits non-zero:

    { "error": { "message": "..." } }

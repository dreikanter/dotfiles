---
name: notes
description: Use the notes CLI to create, list, read, append to, update, annotate, and delete notes in a date-based markdown archive — including daily todos with task rollover and tag operations across the store.
---

# Notes Skill

Use the `notes` CLI for all note operations. All commands respect `$NOTES_PATH` or `--path` (one MUST be set; there is no implicit default).

## Basics

- **Location**: `$NOTES_PATH` (or `--path`); no default — the CLI exits with an error if neither is set.
- **Directory pattern**: `YYYY/MM/YYYYMMDD_ID[_slug][.type].md`
- **UID**: `YYYYMMDD_ID` uniquely identifies each note. `ID` is a small integer that is unique within a day.
- **Type-bearing notes** (`todo`, `backlog`, `weekly`) embed the type as a dot-suffix in the filename, e.g. `20260102_8814.todo.md`. Other types live in the frontmatter only.

The authoritative frontmatter schema is `SCHEMA.md` in the repository. Reserved keys: `title`, `slug`, `type`, `date`, `tags`, `aliases`, `description`, `public`. Unknown keys are preserved verbatim.

## Frontmatter Guidelines

- Include only the fields that are explicitly requested or clearly applicable; everything is optional.
- Do NOT add a `date` field unless the authored date differs from the UID date — the UID-derived date in the filename is the canonical source.
- Add `description` when there is clear context behind the note (e.g. responding to a message, capturing a decision). Use it to record the context/intention, not a summary of the body.
- Inline `#hashtag` tokens in the body are indexed by `notes tags`; they are a separate feature from the `tags` frontmatter list.
- The `slug` in frontmatter is canonical. The filename caches it; on mismatch, frontmatter wins.

## CLI Reference

Most commands that act on a specific note take a numeric ID. To act on "the most recent note of type X" or "the most recent note with slug Y", use `notes ls --limit 1` or `notes resolve` to turn a filter into an ID and shell-substitute.

### Create

```sh
# Empty note
notes new

# Note from stdin with frontmatter
echo "# Content" | notes new --title "Title" --tag journal --tag idea --description "Context"

# Note with a slug
echo "# Content" | notes new --slug my-slug

# Typed note (todo / backlog / weekly trigger special handling; any other type is fine too)
echo "# Content" | notes new --type todo

# Upsert: reuse today's note if one already matches --type/--slug
echo "# Content" | notes new --type todo --upsert

# Today's todo (carries over incomplete tasks from the previous todo)
notes new-todo
```

`notes new` and `notes new-todo` print the absolute path of the created (or reused) file to stdout.

### List

```sh
# Most recent IDs, newest first
notes ls --limit 10

# Filter by type, slug, or tag (--tag is repeatable; tags AND together)
notes ls --type todo --limit 1
notes ls --slug report
notes ls --tag journal --tag idea

# Only today's notes
notes ls --today
```

### Read

```sh
notes read 8823
notes read 8823 --no-frontmatter
```

`notes read` requires a numeric ID. Compose with `ls` or `resolve` to read a filtered note:

```sh
# Read the most recent todo
notes read "$(notes ls --type todo --limit 1)"
```

### Resolve (get path)

```sh
notes resolve                    # most recent note overall
notes resolve --id 8823          # exact ID
notes resolve --type todo        # most recent note of that type
notes resolve --slug meeting     # most recent note with that slug
notes resolve --tag work         # most recent note with that tag
```

At most one lookup flag may be provided.

### Append

```sh
echo "more text" | notes append 8823

# Append to the latest note matching a filter via shell substitution
echo "more text" | notes append "$(notes ls --slug claude-sessions --limit 1)"
```

### Update

```sh
# Set fields
notes update 8823 --title "New Title"
notes update 8823 --description "One-line summary"
notes update 8823 --tag work --tag planning   # replaces existing tags

# Remove fields
notes update 8823 --no-tags
notes update 8823 --no-slug
notes update 8823 --no-type

# Rename / move (the file on disk is renamed automatically)
notes update 8823 --slug meeting
notes update 8823 --type todo
notes update 8823 --date 20260420            # move to a different day

# Visibility
notes update 8823 --public
notes update 8823 --private
```

### Delete

```sh
notes rm 8823
```

### Annotate (auto-fill frontmatter via Claude Code)

```sh
notes annotate 8823
notes annotate 8823 --model claude-sonnet-4-6
notes annotate 8823 --max-chars 4000   # truncate body before sending
notes annotate 8823 --timeout 2m
```

`annotate` shells out to the `claude` CLI and requires `ANTHROPIC_API_KEY`.

### Tags

```sh
# List all tags (frontmatter + body hashtags)
notes tags
notes tags list                  # explicit alias

# Rename a tag across the whole store
notes tags rename work personal
notes tags rename --dry-run work personal

# Delete a tag across the whole store (frontmatter dropped, body '#name' becomes 'name')
notes tags rm work
notes tags rm --dry-run work
```

### Config

```sh
notes config
```

Prints the resolved store path, default values for per-command flags, and the presence of required env vars (`NOTES_PATH`, `ANTHROPIC_API_KEY`). Never prints env values.

### Skill (this document)

```sh
notes skill                              # print this skill to stdout
notes skill --install                    # write into every detected skills-root location
notes skill --install --target=claude    # explicit single-location install
notes skill --install --force            # overwrite an existing diverging copy
notes skill --install --dry-run          # print planned actions, write nothing
```

All targets share the [Agent Skills](https://agentskills.io/specification) format. Supported `--target` values:

- `claude` → `~/.claude/skills/notes/SKILL.md` (read by Claude Code)
- `pi` → `~/.pi/agent/skills/notes/SKILL.md` (read by Pi)
- `agents` → `~/.agents/skills/notes/SKILL.md` (cross-harness convention read by Codex, Cursor, OpenCode, Pi, VS Code Copilot, Warp, and others)

## Editing Notes

Preserve YAML frontmatter structure when modifying notes. When cross-referencing other notes inside a note, prefer the UID (`YYYYMMDD_ID`) — it is stable across renames.

## Composing with the shell

```sh
# Open the most recent meeting note in $EDITOR
$EDITOR "$(notes resolve --slug meeting)"

# Append the current clipboard to today's todo
pbpaste | notes append "$(notes ls --type todo --today --limit 1)"
```

Run `notes <command> --help` for the full flag list of any command. Run `notes config` to inspect the effective runtime configuration.

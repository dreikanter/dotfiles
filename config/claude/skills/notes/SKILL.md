---
name: notes
description: Create and access notes in date-based archive. Create notes with auto-incremented IDs, generate daily todos with task rollover, find latest notes by type (note/todo/backlog/weekly), search by ID/slug/tags/content.
---

# Notes Skill

Use the `notes` CLI tool for all note operations. All commands respect `$NOTES_PATH` or `--path`.

## Basics

- **Location**: `$NOTES_PATH` (defaults to `~/Dropbox/Notes` if not set)
- **Directory pattern**: `YYYY/MM/YYYYMMDD_ID[_slug].md`
- **UID**: `YYYYMMDD_ID` uniquely identifies each note

## Frontmatter Guidelines

- Only include fields that are explicitly requested or clearly applicable
- Do NOT add a `date` field — date is already encoded in the filename
- Add `description` when there is clear context behind the note (e.g., responding to a message, capturing a decision) — use it to record the context/intention, not a summary of the body content
- If there is no clear context/intention, omit the `description` field

## CLI Reference

### Create

```bash
# New note from stdin
echo "# Content" | notes new --slug my-slug

# New note with frontmatter
echo "# Content" | notes new --title "Title" --tag journal --tag idea --description "Context"

# Empty note
notes new

# Today's todo (carries over pending tasks from previous todo)
notes new-todo

# Regenerate today's todo (also carries over in-progress tasks)
notes new-todo --force
```

### Append

```bash
# Append text to a note by ID, slug, or filename
echo "Additional content" | notes append my-slug

# Append with filters
echo "More text" | notes append --slug report --type note
```

### List and Filter

```bash
# List recent notes
notes ls --limit 10

# List by type, slug, or tag
notes ls --type todo --limit 1
notes ls --slug report
notes ls --tag journal --tag idea

# Find notes matching a fragment in ID, slug, or filename
notes filter 8823
notes filter todo
```

### Read

```bash
# Read a note by ID, slug, or filename
notes read 8823
notes read todo

# Read without frontmatter
notes read todo --no-frontmatter

# Path to latest note (optionally filtered by type, slug, or tag)
notes latest
notes latest --type todo
notes latest --slug report
notes latest --tag journal
```

### Search

```bash
# Search note contents (passes args to grep)
notes grep "pattern"
notes grep -i "case insensitive"
notes grep -l "files only"

# Search note contents using ripgrep
notes rg "pattern"
notes rg -i "case insensitive"
notes rg -l "files only"
```

### Path

```bash
# Print the notes archive directory path
notes path
```

Use `notes path` when an agent needs direct access to the notes directory. Always prefer `notes` CLI commands over direct file access.

## Editing Notes

Preserve YAML frontmatter structure when modifying notes. Use UIDs (`YYYYMMDD_ID`) for cross-referencing.

## Advanced: Archive Format Details

For direct file manipulation (custom searches, bulk edits, format-aware processing), see `FORMAT.md` in this skill directory. Only load it when the CLI commands above are insufficient.

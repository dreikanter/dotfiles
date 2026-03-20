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

### Read and Search

```bash
# List recent notes
notes ls --limit 10

# Latest todo/backlog/weekly
notes ls --type todo --limit 1
notes ls --type backlog --limit 1
notes ls --type weekly --limit 1

# Path to latest note (optionally by type)
notes latest
notes latest todo

# Read a note by ID, slug, or filename
notes read 8823
notes read todo

# Read without frontmatter
notes read todo --no-frontmatter

# Find notes matching a fragment
notes filter 8823
notes filter todo
```

### Content Search

Use the Grep tool against `$NOTES_PATH` for content-level searches (tags, active tasks, keywords).

## Editing Notes

Preserve YAML frontmatter structure when modifying notes. Use UIDs (`YYYYMMDD_ID`) for cross-referencing.

## Advanced: Archive Format Details

For direct file manipulation (custom searches, bulk edits, format-aware processing), see `FORMAT.md` in this skill directory. Only load it when the CLI commands above are insufficient.

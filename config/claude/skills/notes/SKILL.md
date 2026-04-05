---
name: notes
description: Create and access notes in date-based archive. Create notes with auto-incremented IDs, generate daily todos with task rollover, resolve notes by type (note/todo/backlog/weekly), search by ID/slug/tags/content.
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

All commands that take a positional argument resolve it by priority:
1. Exact numeric ID (e.g. `8823`)
2. Exact note type (`todo`, `backlog`, `weekly`) — most recent match
3. Path substring — most recent note whose path contains the query

### Create

```bash
# New note from stdin
echo "# Content" | notes new --slug my-slug

# New note with frontmatter
echo "# Content" | notes new --title "Title" --tag journal --tag idea --description "Context"

# Empty note
notes new

# Upsert: return existing note if today already has one matching --type/--slug
echo "# Content" | notes new --slug report --upsert

# Today's todo (carries over pending tasks from previous todo)
notes new-todo

# Regenerate today's todo (also carries over in-progress tasks)
notes new-todo --force
```

### Append

```bash
# Append text to a note by ID, type, or query
echo "Additional content" | notes append my-slug
echo "More text" | notes append todo

# Append to the latest note matching filters
echo "More text" | notes append --slug report --type note
echo "Today only" | notes append --slug report --today
```

### List

```bash
# List recent notes
notes ls --limit 10

# List by type, slug, or tag
notes ls --type todo --limit 1
notes ls --slug report
notes ls --tag journal --tag idea

# List today's notes only
notes ls --today

# Filter by filename fragment
notes ls --name eod
```

### Read

```bash
# Read a note by ID, type, or query
notes read 8823
notes read todo

# Read without frontmatter
notes read todo --no-frontmatter

# Read with filters
notes read --slug report --today
```

### Resolve (get path)

```bash
# Resolve path to latest note by ID, type, or query
notes resolve
notes resolve todo
notes resolve 8823

# Resolve with filters
notes resolve --type todo
notes resolve --slug report
notes resolve --tag journal
notes resolve --today
```

### Update

```bash
# Update frontmatter fields
notes update 8823 --title "New Title" --tag newtag

# Update slug (renames file)
notes update todo --slug daily-todo

# Remove fields
notes update 8823 --no-tags --no-slug
```

### Delete

```bash
notes rm 8823
notes rm --today  # restrict to today's notes
```

### Edit (open in editor)

```bash
notes edit 8823
notes edit todo
```

### Search

```bash
# Search note contents (passes args to grep)
notes grep "pattern"
notes grep -l "files only"

# Search note contents using ripgrep
notes rg "pattern"
notes rg -l "files only"
```

## Editing Notes

Preserve YAML frontmatter structure when modifying notes. Use UIDs (`YYYYMMDD_ID`) for cross-referencing.

## Advanced: Archive Format Details

For direct file manipulation (custom searches, bulk edits, format-aware processing), see `FORMAT.md` in this skill directory. Only load it when the CLI commands above are insufficient.

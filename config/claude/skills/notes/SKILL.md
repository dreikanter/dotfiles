---
name: notes
description: Create and access notes in date-based archive. Create notes with auto-incremented IDs, generate daily todos with task rollover, find latest notes by type (note/todo/backlog/weekly), search by ID/slug/tags/content.
---

# Notes Skill

## Archive Structure

**Location**: `$NOTES_PATH` (defaults to `~/Dropbox/Notes` if not set)

**Directory Hierarchy**: `YYYY/MM/YYYYMMDD_ID[_slug].md`

**Examples**:
- `2026/01/20260106_8823.md` - no slug
- `2026/01/20260102_8814_todo.md` - with slug
- `2024/12/20241203_6973_disable-letter_opener.md` - descriptive slug

**ID Tracking**: Sequential IDs stored in `$NOTES_PATH/id.json`

**UID (Unique Identifier)**: `YYYYMMDD_ID` uniquely identifies each note

## File Format

**YAML Frontmatter (Optional)**:
```yaml
---
title: Note title
tags: [tag1, tag2, tag3]
slug: short-name
description: Brief description
---
```

**Frontmatter rules**:
- Only include fields that are explicitly requested or clearly applicable
- Do NOT add a `date` field — date is already encoded in the filename
- Add `description` when there is clear context behind the note (e.g., responding to a message, capturing a decision, summarizing a conversation) — use it to record the context/intention, not a summary of the body content
- If there is no clear context/intention behind the new note, prefer not to include `description` field (avoid generic/non-informative descriptions)

**Task Syntax** (in `*_todo.md` notes):
- `[+]` - Completed
- `[>]` - Moved to future date
- `[ ]` - Pending
- `[daily]` - Tag for daily recurring tasks

## CLI Reference

The `notes` CLI tool handles all note operations. All commands respect `$NOTES_PATH` or `--path`.

### Create

```bash
# New note from stdin
echo "# Content" | notes new --slug my-slug

# New note with frontmatter
echo "# Content" | notes new --tag journal --tag idea --description "Context"

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

# Read a note by ID, slug, or filename
notes read 8823
notes read todo

# Find notes matching a fragment
notes filter 8823
notes filter todo
```

### Content search

Use the Grep tool against `$NOTES_PATH` for content-level searches (tags, active tasks, keywords).

## Editing Notes

Preserve YAML frontmatter structure when modifying notes. Use UIDs (`YYYYMMDD_ID`) for cross-referencing.

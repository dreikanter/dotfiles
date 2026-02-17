---
name: notes-archive
description: Create and access notes in date-based archive. Create notes with auto-incremented IDs, generate daily todos with task rollover, find latest notes by type (note/todo/backlog/weekly), search by ID/slug/tags/content.
---

# Notes Archive Skill

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
date: YYYY-MM-DD
tags: [tag1, tag2, tag3]
slug: short-name
description: Brief description
---
```

**Task Syntax** (in `*_todo.md` notes):
- `[+]` - Completed
- `[>]` - In progress
- `[ ]` - Pending
- `[daily]` - Tag for daily recurring tasks

## Agent Scripts

**Location**: `bin/` subdirectory within this skill (`~/.claude/skills/notes-archive/bin/`)

**Usage**: When this skill is invoked, reference scripts as: `~/.claude/skills/notes-archive/bin/SCRIPT_NAME`

### create-note `[slug]`
Creates note with auto-incremented ID, updates id.json
- Input: Content from stdin
- Output: Created file path to stdout
- Example: `echo "# My Note" | ~/.claude/skills/notes-archive/bin/create-note my-slug`

### create-todo `[--force]`
Creates today's todo note by carrying over incomplete tasks from previous todo
- Finds most recent todo note and extracts pending (`[ ]`) and in-progress (`[>]`) tasks
- Daily tasks (marked with `[daily]`) are always included
- Marks copied pending tasks as in-progress in previous todo
- Creates new todo with slug `todo` and auto-incremented ID
- If today's todo already exists, returns existing path (use `--force` to regenerate)
- Output: Created/existing file path to stdout
- Example: `~/.claude/skills/notes-archive/bin/create-todo`

### latest-note-path
Outputs path to most recent note (skips `99999999_*` pinned notes)

### latest-todo-path
Outputs path to most recent `*_todo.md` note

### latest-backlog-path
Outputs path to most recent `*_backlog.md` note

### latest-weekly-path
Outputs path to most recent `*_weekly.md` note

**Error handling**: All scripts check for `$NOTES_PATH` and exit with error to stderr if missing or invalid.

**Pinned Notes**: Files starting with `99999999_*` are excluded from `latest-*` searches.

## Common Search Patterns

**Find by ID or slug**:
```bash
find . -name "*_8823*.md"  # by ID
find . -name "*_todo.md"    # by slug
```

**Find by date**:
```bash
ls 2026/01/
ls 2026/01/20260106_*.md
```

**Search content**:
```bash
grep -r "search-term" 2026/
grep -r "^tags:" --include="*.md"
```

**Active tasks**:
```bash
grep -r "^\[>\]" --include="*_todo.md"
```

**Tag analysis**:
```bash
# Tag frequency
grep -rh "^tags:" --include="*.md" | sed 's/tags: \[\(.*\)\]/\1/' | tr ',' '\n' | sed 's/^ *//;s/ *$//' | sort | uniq -c | sort -rn

# Common slugs
find . -name "*_*.md" | sed 's/.*_\([^.]*\)\.md/\1/' | grep -vE '^\d+$' | sort | uniq -c | sort -rn | head -10
```

## Usage Guidelines

- **Create notes**: Use `bin/create-note` or `bin/create-todo` scripts
- **Access notes**: Use `bin/latest-*-path` scripts to get file paths, then Read tool to view
- **Search**: Use Grep/Glob tools or bash commands from "Common Search Patterns" section
- **Editing**: Preserve YAML frontmatter structure when modifying notes
- **References**: Use UIDs (`YYYYMMDD_ID`) for cross-referencing notes

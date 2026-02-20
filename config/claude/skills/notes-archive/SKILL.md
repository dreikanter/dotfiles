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

### dump-chat `<session-id-or-jsonl-path> <output-notes-path>`
Exports a Claude Code chat session to a Markdown notes file.
- Reads the session's `.jsonl` file from `~/.claude/projects/`
- Pulls title/summary from `sessions-index.json`, falls back to first user message
- Preserves: session ID, model name, Claude Code version, project path, git branch, creation timestamp, per-message timestamps
- Skips tool results, thinking blocks, and sidechain messages — primary dialog only
- Output file is overwritten if it already exists (idempotent for updates)
- Templates for heading and messages are defined at the top of the script for easy customisation
- Example: `~/.claude/skills/notes-archive/bin/dump-chat ade243b9-7ea3-4fa0-8277 ~/Dropbox/Notes/2026/02/20260218_9004_chat-dump.md`

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

## Chat History Dumps

Use `bin/dump-chat` to save the current (or any past) Claude Code chat session as a note.

### Finding the current session ID
The current session's `.jsonl` file is the most recently modified file in:
`~/.claude/projects/<project-dir>/`

Use: `ls -lt ~/.claude/projects/<project-dir>/*.jsonl | head -1`

The filename (without `.jsonl`) is the session ID.

### Workflow

**"Dump this chat"** (first time or explicitly new):
1. Find current session ID from most recent `.jsonl`
2. Create new note: `~/.claude/skills/notes-archive/bin/create-note chat-dump` (pipe empty content or use touch)
3. Run: `~/.claude/skills/notes-archive/bin/dump-chat <session-id> <new-note-path>`
4. Report the note path

**"Dump this chat"** (repeated request, no "new file" / "copy" mentioned):
1. Find the most recently modified `*_chat-dump.md` note (Glob: `$NOTES_PATH/**/*_chat-dump.md`, pick newest mtime)
2. Run: `~/.claude/skills/notes-archive/bin/dump-chat <session-id> <existing-note-path>` (overwrites in place)
3. Report the note path

**"Save a copy" / "save to a new file"**: Always create a new note regardless.

### `/dump` slash command
When the user types `/dump`, treat it as "dump this chat to a note" using the workflow above (update existing `chat-dump` note if one exists for today, otherwise create new).

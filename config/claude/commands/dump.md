---
description: Dump current chat history to a new note
---

Use the notes-archive skill to dump the current chat session to a note.

Follow the "Chat History Dumps" workflow from the notes-archive skill:

1. Find the current session ID: the most recently modified `.jsonl` in `~/.claude/projects/<project-dir>/` where `<project-dir>` matches the current working directory path (dashes replacing slashes).
2. Check for an existing `*_chat-dump.md` note (Glob `$NOTES_PATH/**/*_chat-dump.md`, pick the one with the newest mtime). If one exists and was created today, update it in place. Otherwise create a new note with slug `chat-dump` via `bin/create-note chat-dump` (pass empty content).
3. Run `~/.claude/skills/notes-archive/bin/dump-chat <session-id> <note-path>`.
4. Report the note path to the user.

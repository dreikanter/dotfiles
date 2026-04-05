---
description: Dump current chat history to a new note
---

Dump the current chat session to a note.

1. Find the current session ID: the most recently modified `.jsonl` in `~/.claude/projects/<project-dir>/` where `<project-dir>` matches the current working directory path (dashes replacing slashes).
2. Check for an existing `*_chat-dump.md` note (`notes ls --name chat-dump --today`). If one exists, update it in place. Otherwise create a new note: `notes new --slug chat-dump`.
3. Read the session `.jsonl` file. For each entry with `type` "user" or "assistant" (skip `isMeta` and `isSidechain` entries), extract the text content. Format as `[HH:MM:SS] **Role:** text`. Skip tool results and thinking blocks.
4. Write the formatted content to the note path (prepend YAML frontmatter with `tags: [chat-history]` and `slug: chat-dump`).
5. Report the note path to the user.

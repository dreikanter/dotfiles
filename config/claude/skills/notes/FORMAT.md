# Notes Archive Format

Detailed format specification for direct file access. Only needed when the `notes` CLI is insufficient.

## Directory Structure

**Hierarchy**: `$NOTES_PATH/YYYY/MM/YYYYMMDD_ID[_slug].md`

**Examples**:
- `2026/01/20260106_8823.md` — no slug
- `2026/01/20260102_8814_todo.md` — with slug
- `2024/12/20241203_6973_disable-letter_opener.md` — descriptive slug

**ID Tracking**: Sequential IDs stored in `$NOTES_PATH/id.json`

## YAML Frontmatter

Optional block at the top of each note:

```yaml
---
title: Note title
tags: [tag1, tag2, tag3]
slug: short-name
description: Brief description
---
```

## Task Syntax

Used in `*_todo.md` notes:

- `[+]` (prefix) — Completed
- `[ ]` (prefix) — Pending
- `[daily]` (tag) — Tag for daily recurring tasks
- `(moved)` (tag) — Moved to future date

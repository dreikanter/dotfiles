---
name: firefox-bookmarks
description: Analyze Firefox bookmarks and tags directly from the places.sqlite database. Extract recent bookmarks, analyze tag popularity, find bookmark statistics, and explore bookmark metadata. Use when working with Firefox bookmarks, analyzing bookmark usage, organizing tags, or extracting bookmark data from Firefox profiles.
---

# Firefox Bookmarks Analyzer

## Overview

This Skill provides direct access to Firefox bookmark data by querying the places.sqlite database. It includes utilities for extracting bookmarks, analyzing tags, and generating insights about bookmark usage.

## Capabilities

- **Extract recent bookmarks** with metadata (URL, title, date added, last visited)
- **Analyze bookmark tags** to find most popular tags and tag usage statistics
- **Query Firefox database** directly using SQLite
- **Database schema exploration** to understand Firefox's bookmark structure
- **Cross-platform support** for macOS, Linux, and Windows Firefox profiles

## Prerequisites

- Ruby (system Ruby is sufficient)
- sqlite3 gem (usually pre-installed on macOS)
- Firefox installed with existing bookmarks

## Instructions

When the user asks to work with Firefox bookmarks, follow these steps:

### 1. Understanding User Intent

Determine what the user wants:
- **List recent bookmarks**: Use the bookmark extraction script
- **Analyze tags**: Use the tag analysis script
- **Explore database**: Use database exploration utilities
- **Custom queries**: Help write SQLite queries against places.sqlite

### 2. Locate Firefox Profile

The scripts automatically find the Firefox profile using these paths:
- **macOS**: `~/Library/Application Support/Firefox/Profiles/*default*`
- **Linux**: `~/.mozilla/firefox/*default*`
- **Windows**: `~/AppData/Roaming/Mozilla/Firefox/Profiles/*default*`

### 3. Run Appropriate Script

Use the scripts located in `~/.claude/skills/firefox-bookmarks/scripts/`:

**Extract Recent Bookmarks:**
```bash
ruby ~/.claude/skills/firefox-bookmarks/scripts/extract_bookmarks.rb [limit]
```

**Analyze Tags:**
```bash
ruby ~/.claude/skills/firefox-bookmarks/scripts/analyze_tags.rb
```

**Explore Database:**
```bash
ruby ~/.claude/skills/firefox-bookmarks/scripts/explore_db.rb
```

### 4. Present Results

- Format the output clearly for the user
- Highlight key insights (most used tags, recently added bookmarks, etc.)
- Suggest follow-up actions or analyses

## Common Use Cases

### Use Case 1: Find Recent Bookmarks
User asks: "What are my most recent Firefox bookmarks?"

Response: Run `extract_bookmarks.rb` with default limit (50) and show the results.

### Use Case 2: Tag Analysis
User asks: "What are my most popular bookmark tags?"

Response: Run `analyze_tags.rb` and present the top tags with usage counts.

### Use Case 3: Custom Analysis
User asks: "Show me all bookmarks tagged with 'ruby'"

Response: Write a custom SQLite query to filter by specific tag.

### Use Case 4: Database Exploration
User asks: "How does Firefox store bookmarks?"

Response: Run `explore_db.rb` to show the database schema and explain the structure.

## Database Structure Reference

Firefox stores bookmarks in `places.sqlite` with these key tables:

- **moz_bookmarks**: Bookmark entries, folders, and tags
  - `id`: Unique identifier
  - `type`: 1=bookmark, 2=folder
  - `fk`: Foreign key to moz_places (NULL for folders/tags)
  - `parent`: Parent folder ID
  - `title`: Bookmark/folder/tag name
  - `dateAdded`: Timestamp in microseconds
  - `lastModified`: Last modification timestamp

- **moz_places**: URL and visit data
  - `id`: Unique identifier
  - `url`: The URL
  - `title`: Page title
  - `visit_count`: Number of visits
  - `last_visit_date`: Last visit timestamp

- **Tags Structure**: Tags are stored as folders with parent ID 4
  - Tag folder: `parent=4, fk=NULL, title=tag_name`
  - Tagged bookmarks: Children of tag folder

## Safety Features

All scripts create temporary copies of places.sqlite to avoid:
- Database locking issues (Firefox may have the DB open)
- Accidental data corruption
- Read-only access ensures no modifications

## Error Handling

If scripts fail:
1. **Firefox not found**: Check Firefox installation and profile location
2. **Database locked**: Close Firefox and retry
3. **Missing dependencies**: Install sqlite3 gem (`gem install sqlite3 --user-install`)
4. **Permission errors**: Check file permissions on Firefox profile directory

## Advanced Usage

### Custom Queries

Help users write custom SQLite queries:

```sql
-- Find bookmarks by keyword in title
SELECT url, title, datetime(dateAdded/1000000, 'unixepoch') as added
FROM moz_bookmarks b
JOIN moz_places p ON b.fk = p.id
WHERE p.title LIKE '%keyword%'
ORDER BY dateAdded DESC;
```

### Filtering and Aggregation

Examples of useful analyses:
- Bookmarks added in last 30 days
- Most visited bookmarked pages
- Untagged bookmarks
- Bookmark folder depth analysis
- Duplicate URL detection

## Archiving Project Folders (on request only)

Never run this as part of a normal bookmark query. Only start it when the user
explicitly asks to archive project folders.

Some bookmarks-toolbar folders group links for a single piece of work (a Jira
epic, a Confluence page, a Figma file, a related PR). Archiving means renaming
such a folder to `YYYY-MM-DD <name>` using its own `dateAdded`, then moving it
into a toolbar folder called `Projects`.

### Flow

1. List toolbar folders that are not yet archived. Toolbar parent id is `3`.
   Skip folders already named with a `YYYY-MM-DD ` prefix, and skip `Projects`
   itself. Show a numbered list so the user can answer with numbers:

   ```
   1. Summaries       2026-04-13   4 items
   2. Glow Up         2026-04-23   3 items
   ```

   Include item counts, and briefly note which folders look like utility or
   reading-list folders rather than projects. The user decides, not the script.

2. Wait for the user to pick numbers. Never archive everything by default.

3. Confirm Firefox is fully closed (`pgrep -fl "Firefox.app/Contents/MacOS/firefox"`).
   Writing to a live `places.sqlite` risks Firefox overwriting the change or
   corrupting the file. If Firefox is running, stop and ask the user to quit it.

4. Back up first: `sqlite3 places.sqlite ".backup '<path>'"`. Report the path.

5. Apply the change in one transaction, then verify and run
   `pragma integrity_check`.

### SQL shape

Create `Projects` only when it is missing. Generate a fresh 12-character guid
(`openssl rand -base64 9 | tr '+/' '-_' | cut -c1-12`) since the guid index is
unique.

```sql
begin;
-- create Projects only if absent
insert into moz_bookmarks (type, fk, parent, position, title, dateAdded, lastModified, guid, syncStatus, syncChangeCounter)
select 2, null, 3, (select coalesce(max(position), -1) + 1 from moz_bookmarks where parent = 3),
       'Projects', strftime('%s','now')*1000000, strftime('%s','now')*1000000, '<new-guid>', 1, 1
where not exists (select 1 from moz_bookmarks where parent = 3 and type = 2 and title = 'Projects');

-- rename only folders that lack the date prefix, using their own dateAdded
update moz_bookmarks
set title = strftime('%Y-%m-%d', dateAdded/1000000, 'unixepoch') || ' ' || title,
    lastModified = strftime('%s','now')*1000000,
    syncChangeCounter = syncChangeCounter + 1
where id in (<selected ids>)
  and title not glob '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] *';

-- move into Projects, appending after whatever is already there
update moz_bookmarks
set parent = (select id from moz_bookmarks where parent = 3 and type = 2 and title = 'Projects'),
    position = (select coalesce(max(position), -1) from moz_bookmarks
                where parent = (select id from moz_bookmarks where parent = 3 and type = 2 and title = 'Projects'))
               + 1 + <rank of this folder within the selection, starting at 1>,
    lastModified = strftime('%s','now')*1000000,
    syncChangeCounter = syncChangeCounter + 1
where id in (<selected ids>);
commit;
```

After the move, close the position gap left on the toolbar by renumbering the
remaining `parent = 3` rows sequentially from 0, ordered by their current
position. Firefox tolerates gaps, but sequential positions keep the toolbar
order predictable.

### Rules

- Only `UPDATE` titles, `parent`, `position`, `lastModified`, `syncChangeCounter`,
  and `INSERT` the `Projects` folder. Never `DELETE` from `moz_bookmarks`, and
  never touch `moz_places`.
- Idempotent: re-running must not double-prefix a title, create a second
  `Projects` folder, or reorder folders already inside it.
- Match `Projects` by `parent = 3 and type = 2 and title = 'Projects'` so an
  existing folder is reused.
- Bookmarks inside an archived folder move with it. Nothing is copied or removed.
- Ask the user to reopen Firefox and confirm the toolbar looks right.

## Limitations

- Read-only access (cannot modify bookmarks)
- Requires Firefox to be closed for reliable database access (scripts use temp copies)
- Tag analysis only works if user has created tags in Firefox

## Scripts

- `scripts/extract_bookmarks.rb` - Extract recent bookmarks with metadata
- `scripts/analyze_tags.rb` - Analyze tag popularity and usage
- `scripts/explore_db.rb` - Explore Firefox database structure

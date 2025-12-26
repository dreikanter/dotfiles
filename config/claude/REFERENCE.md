# Firefox Bookmarks - Technical Reference

## Database Overview

Firefox stores all bookmarks, history, and metadata in a SQLite database file called `places.sqlite` located in the user's Firefox profile directory.

## Profile Locations

### macOS
```
~/Library/Application Support/Firefox/Profiles/<profile-name>/places.sqlite
```

### Linux
```
~/.mozilla/firefox/<profile-name>/places.sqlite
```

### Windows
```
%APPDATA%\Mozilla\Firefox\Profiles\<profile-name>\places.sqlite
```

Profile names typically end with `.default` or `.default-release`.

## Database Schema

### moz_bookmarks Table

Primary table for bookmark hierarchy and organization.

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key, unique identifier |
| type | INTEGER | 1=bookmark, 2=folder, 3=separator |
| fk | INTEGER | Foreign key to moz_places.id (NULL for folders/tags) |
| parent | INTEGER | Parent folder ID (self-referencing) |
| position | INTEGER | Order within parent folder |
| title | LONGVARCHAR | Bookmark/folder/tag name |
| keyword_id | INTEGER | Associated keyword for quick access |
| folder_type | TEXT | Special folder type (e.g., 'tags', 'toolbar') |
| dateAdded | INTEGER | Creation timestamp (microseconds since Unix epoch) |
| lastModified | INTEGER | Last modification timestamp (microseconds) |
| guid | TEXT | Global unique identifier |
| syncStatus | INTEGER | Firefox Sync status |
| syncChangeCounter | INTEGER | Change counter for sync |

### moz_places Table

Stores URL information and visit metadata.

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key |
| url | LONGVARCHAR | The complete URL |
| title | LONGVARCHAR | Page title from last visit |
| rev_host | LONGVARCHAR | Reversed hostname for grouping |
| visit_count | INTEGER | Total number of visits |
| hidden | INTEGER | Hidden from history view (0/1) |
| typed | INTEGER | Manually typed in address bar (0/1) |
| frecency | INTEGER | Frequency + recency score |
| last_visit_date | INTEGER | Last visit timestamp (microseconds) |
| guid | TEXT | Global unique identifier |
| foreign_count | INTEGER | Number of references from other tables |
| url_hash | INTEGER | Hash of URL for faster lookups |
| description | TEXT | Meta description from page |
| preview_image_url | TEXT | Preview/thumbnail image URL |
| site_name | TEXT | Site name from meta tags |

### Special Bookmark Folders

Firefox creates these root folders:

| ID | Title | Description |
|----|-------|-------------|
| 1 | (root) | Root of bookmark tree |
| 2 | menu | Bookmarks Menu |
| 3 | toolbar | Bookmarks Toolbar |
| 4 | tags | Tags root folder |
| 5 | unfiled | Unsorted Bookmarks |
| 6 | mobile | Mobile Bookmarks (Firefox Sync) |

## Tag Storage Structure

Tags are stored as a hierarchy within moz_bookmarks:

```
tags (id=4, parent=1)
├── tag1 (type=2, fk=NULL, parent=4)
│   ├── bookmark1 (type=1, fk=123, parent=tag1.id)
│   └── bookmark2 (type=1, fk=456, parent=tag1.id)
└── tag2 (type=2, fk=NULL, parent=4)
    └── bookmark3 (type=1, fk=789, parent=tag2.id)
```

**Key Properties:**
- Tag folders have `parent=4` (tags root)
- Tag folders have `fk=NULL` (not linked to a URL)
- Tag folders have `type=2` (folder type)
- Tagged bookmarks are children of tag folders
- Same bookmark can appear under multiple tag folders

## Timestamp Format

Firefox stores timestamps as **microseconds** since Unix epoch (1970-01-01 00:00:00 UTC).

**Conversion to readable format:**

```sql
-- SQLite conversion
datetime(dateAdded/1000000, 'unixepoch', 'localtime')

-- Ruby conversion
Time.at(timestamp / 1_000_000)

-- JavaScript conversion
new Date(timestamp / 1000)
```

## Common Queries

### Get All Bookmarks with URLs

```sql
SELECT
  b.id,
  b.title as bookmark_title,
  p.url,
  p.title as page_title,
  datetime(b.dateAdded/1000000, 'unixepoch', 'localtime') as date_added,
  datetime(p.last_visit_date/1000000, 'unixepoch', 'localtime') as last_visited
FROM moz_bookmarks b
JOIN moz_places p ON b.fk = p.id
WHERE b.type = 1
  AND p.url IS NOT NULL
ORDER BY b.dateAdded DESC;
```

### Get All Tags with Bookmark Counts

```sql
SELECT
  tag_folder.title as tag,
  COUNT(*) as bookmark_count
FROM moz_bookmarks tag_folder
JOIN moz_bookmarks tagged_item ON tagged_item.parent = tag_folder.id
WHERE tag_folder.parent = 4
  AND tag_folder.fk IS NULL
GROUP BY tag_folder.title
ORDER BY bookmark_count DESC;
```

### Get Bookmarks by Specific Tag

```sql
SELECT
  p.url,
  p.title,
  datetime(b.dateAdded/1000000, 'unixepoch', 'localtime') as added
FROM moz_bookmarks tag_folder
JOIN moz_bookmarks b ON b.parent = tag_folder.id
JOIN moz_places p ON b.fk = p.id
WHERE tag_folder.parent = 4
  AND tag_folder.title = 'ruby'
ORDER BY b.dateAdded DESC;
```

### Get Untagged Bookmarks

```sql
SELECT
  p.url,
  p.title,
  b.title as bookmark_title
FROM moz_bookmarks b
JOIN moz_places p ON b.fk = p.id
WHERE b.type = 1
  AND b.id NOT IN (
    SELECT tagged_item.id
    FROM moz_bookmarks tag_folder
    JOIN moz_bookmarks tagged_item ON tagged_item.parent = tag_folder.id
    WHERE tag_folder.parent = 4
  )
ORDER BY b.dateAdded DESC;
```

### Get Most Visited Bookmarked Pages

```sql
SELECT
  p.url,
  p.title,
  p.visit_count,
  datetime(p.last_visit_date/1000000, 'unixepoch', 'localtime') as last_visit
FROM moz_bookmarks b
JOIN moz_places p ON b.fk = p.id
WHERE b.type = 1
  AND p.visit_count > 0
ORDER BY p.visit_count DESC
LIMIT 50;
```

### Get Bookmarks Added in Last 30 Days

```sql
SELECT
  p.url,
  p.title,
  datetime(b.dateAdded/1000000, 'unixepoch', 'localtime') as added
FROM moz_bookmarks b
JOIN moz_places p ON b.fk = p.id
WHERE b.type = 1
  AND b.dateAdded > (strftime('%s', 'now', '-30 days') * 1000000)
ORDER BY b.dateAdded DESC;
```

### Find Duplicate URLs

```sql
SELECT
  p.url,
  COUNT(*) as count,
  GROUP_CONCAT(b.title, ' | ') as bookmark_titles
FROM moz_bookmarks b
JOIN moz_places p ON b.fk = p.id
WHERE b.type = 1
GROUP BY p.url
HAVING count > 1
ORDER BY count DESC;
```

## Ruby Script Structure

All scripts follow this pattern:

```ruby
#!/usr/bin/env ruby

require 'sqlite3'
require 'fileutils'

# 1. Find Firefox profile
def find_firefox_profile
  case RUBY_PLATFORM
  when /darwin/
    base_path = File.expand_path("~/Library/Application Support/Firefox/Profiles")
  when /linux/
    base_path = File.expand_path("~/.mozilla/firefox")
  when /win32|mingw/
    base_path = File.expand_path("~/AppData/Roaming/Mozilla/Firefox/Profiles")
  end

  profiles = Dir.glob(File.join(base_path, "*default*"))
  profiles.max_by { |p| File.mtime(p) }
end

# 2. Create temporary database copy
profile = find_firefox_profile
places_db = File.join(profile, 'places.sqlite')
temp_db = "/tmp/places_copy_#{Time.now.to_i}.sqlite"
FileUtils.cp(places_db, temp_db)

# 3. Query database
begin
  db = SQLite3::Database.new(temp_db)
  db.results_as_hash = true

  results = db.execute("SELECT ...")

  db.close
ensure
  File.delete(temp_db) if File.exist?(temp_db)
end
```

## Best Practices

### Database Access

1. **Always use temporary copies**: Never query places.sqlite directly
2. **Clean up temp files**: Use ensure blocks to delete temporary databases
3. **Handle locked databases**: Firefox may lock the database when running

### Query Optimization

1. **Use indexes**: Firefox creates indexes on frequently queried columns
2. **Limit results**: Use LIMIT for large result sets
3. **Filter early**: Apply WHERE clauses before JOINs when possible

### Error Handling

```ruby
begin
  # Database operations
rescue SQLite3::Exception => e
  puts "Database error: #{e.message}"
  []
ensure
  # Cleanup
  File.delete(temp_db) if File.exist?(temp_db)
end
```

## Security Considerations

- **Read-only access**: Scripts only read, never modify
- **Temporary copies**: Original database remains untouched
- **Privacy**: Bookmark data may contain sensitive information
- **Local only**: All processing happens locally, no network access

## Performance Notes

- places.sqlite size: Typically 5-50 MB
- Query performance: Most queries execute in < 100ms
- Profile detection: Cached for performance
- Temporary copies: Minimal overhead, ensures database integrity

## Troubleshooting

### Script fails with "database locked"
- Firefox is running with the database open
- Solution: Scripts use temporary copies, this shouldn't happen

### Script fails with "no such table"
- Firefox version may use different schema
- Solution: Check Firefox version and schema compatibility

### No bookmarks found
- Check if Firefox profile path is correct
- Verify bookmarks exist in Firefox
- Check query filters (date ranges, type filters)

### Missing sqlite3 gem
```bash
# Install for user only (no sudo)
gem install sqlite3 --user-install

# Or for specific Ruby version
gem install sqlite3 -v 1.4.4 --user-install
```

## Further Reading

- [Firefox Places Database Schema (Mozilla Wiki)](https://wiki.mozilla.org/Places:Design_Overview)
- [SQLite Documentation](https://www.sqlite.org/docs.html)
- [Firefox Profile Manager](https://support.mozilla.org/en-US/kb/profile-manager-create-remove-switch-firefox-profiles)

# Firefox Bookmarks - Usage Examples

## Quick Start

### Example 1: View Recent Bookmarks

**User Request:**
"Show me my 20 most recent Firefox bookmarks"

**Assistant Response:**
```bash
ruby ~/.claude/skills/firefox-bookmarks/scripts/extract_bookmarks.rb 20
```

**Sample Output:**
```
Extracting 20 most recent bookmarks from Firefox...
================================================================================
RECENT FIREFOX BOOKMARKS (20 found)
================================================================================

1. Saleae
   URL: https://saleae.com/
   Added: 2025-12-24 13:32:28
   Last Visited: 2025-12-24 13:32:18
   ----------------------------------------------------------------------------

2. ON1 Photo RAW 2026 Release Notes
   URL: https://on1help.zendesk.com/hc/en-us/articles/39165360108045
   Added: 2025-12-23 22:47:23
   Last Visited: 2025-12-23 22:47:11
   ----------------------------------------------------------------------------

[... 18 more bookmarks ...]
```

### Example 2: Analyze Tag Popularity

**User Request:**
"What are my most popular Firefox bookmark tags?"

**Assistant Response:**
```bash
ruby ~/.claude/skills/firefox-bookmarks/scripts/analyze_tags.rb
```

**Sample Output:**
```
Analyzing Firefox bookmark tags...

================================================================================
FIREFOX BOOKMARK TAGS ANALYSIS
================================================================================

Total unique tags: 352

--------------------------------------------------------------------------------

1. eurorack
   Used 45 times
   Sample bookmarks:
     - Calsynth
     - VCV Rack Documentation
     - Mutable Instruments
   ----------------------------------------------------------------------------

2. apps
   Used 33 times
   Sample bookmarks:
     - NetNewsWire: Free and Open Source RSS Reader
     - Flow. Get Things Done. – Best Pomodoro Timer
     - IINA - The modern media player for macOS
   ----------------------------------------------------------------------------

3. ruby
   Used 23 times
   Sample bookmarks:
     - Ruby on Rails Admin Panel Framework · Avo
     - railsrout.es — play with Rails routes in realtime
   ----------------------------------------------------------------------------

[... more tags ...]
```

### Example 3: Explore Database Structure

**User Request:**
"How does Firefox organize bookmarks in its database?"

**Assistant Response:**
```bash
ruby ~/.claude/skills/firefox-bookmarks/scripts/explore_db.rb
```

**Sample Output:**
```
================================================================================
DATABASE SCHEMA
================================================================================

Tables:
  - moz_bookmarks
  - moz_places
  - moz_historyvisits
  - moz_keywords
  [... more tables ...]

================================================================================
moz_bookmarks table structure:
================================================================================
  id (INTEGER)
  type (INTEGER)
  fk (INTEGER)
  parent (INTEGER)
  title (LONGVARCHAR)
  dateAdded (INTEGER)
  lastModified (INTEGER)
  [... more columns ...]
```

## Advanced Queries

### Example 4: Find Bookmarks by Tag

**User Request:**
"Show me all bookmarks tagged with 'ruby'"

**Custom Query:**
```ruby
#!/usr/bin/env ruby
require 'sqlite3'
require 'fileutils'

# Find Firefox profile
base_path = File.expand_path("~/Library/Application Support/Firefox/Profiles")
profiles = Dir.glob(File.join(base_path, "*default*"))
profile = profiles.max_by { |p| File.mtime(p) }
places_db = File.join(profile, 'places.sqlite')

# Create temporary copy
temp_db = "/tmp/places_query_#{Time.now.to_i}.sqlite"
FileUtils.cp(places_db, temp_db)

begin
  db = SQLite3::Database.new(temp_db)
  db.results_as_hash = true

  query = <<~SQL
    SELECT
      p.url,
      p.title,
      datetime(b.dateAdded/1000000, 'unixepoch', 'localtime') as added
    FROM moz_bookmarks tag_folder
    JOIN moz_bookmarks b ON b.parent = tag_folder.id
    JOIN moz_places p ON b.fk = p.id
    WHERE tag_folder.parent = 4
      AND tag_folder.title = 'ruby'
    ORDER BY b.dateAdded DESC
  SQL

  results = db.execute(query)

  puts "Bookmarks tagged with 'ruby': #{results.length}"
  puts "=" * 80

  results.each_with_index do |row, i|
    puts "\n#{i + 1}. #{row['title']}"
    puts "   URL: #{row['url']}"
    puts "   Added: #{row['added']}"
  end

  db.close
ensure
  File.delete(temp_db) if File.exist?(temp_db)
end
```

### Example 5: Find Untagged Bookmarks

**User Request:**
"Which of my bookmarks don't have any tags?"

**Custom Query:**
```ruby
query = <<~SQL
  SELECT
    p.url,
    b.title,
    datetime(b.dateAdded/1000000, 'unixepoch', 'localtime') as added
  FROM moz_bookmarks b
  JOIN moz_places p ON b.fk = p.id
  WHERE b.type = 1
    AND b.id NOT IN (
      SELECT tagged_item.id
      FROM moz_bookmarks tag_folder
      JOIN moz_bookmarks tagged_item ON tagged_item.parent = tag_folder.id
      WHERE tag_folder.parent = 4
    )
  ORDER BY b.dateAdded DESC
  LIMIT 50
SQL
```

### Example 6: Most Visited Bookmarked Sites

**User Request:**
"What are my most frequently visited bookmarked websites?"

**Custom Query:**
```ruby
query = <<~SQL
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
  LIMIT 25
SQL
```

**Sample Output:**
```
Top 25 Most Visited Bookmarked Sites
================================================================================

1. GitHub (342 visits)
   Last visited: 2025-12-25 14:23:15

2. Stack Overflow (287 visits)
   Last visited: 2025-12-24 09:45:33

[... more results ...]
```

### Example 7: Recent Bookmarks (Last 7 Days)

**User Request:**
"Show me bookmarks I added in the last week"

**Custom Query:**
```ruby
query = <<~SQL
  SELECT
    p.url,
    p.title,
    datetime(b.dateAdded/1000000, 'unixepoch', 'localtime') as added
  FROM moz_bookmarks b
  JOIN moz_places p ON b.fk = p.id
  WHERE b.type = 1
    AND b.dateAdded > (strftime('%s', 'now', '-7 days') * 1000000)
  ORDER BY b.dateAdded DESC
SQL
```

### Example 8: Find Duplicate Bookmarks

**User Request:**
"Do I have any duplicate bookmark URLs?"

**Custom Query:**
```ruby
query = <<~SQL
  SELECT
    p.url,
    COUNT(*) as duplicate_count,
    GROUP_CONCAT(b.title, ' | ') as bookmark_titles
  FROM moz_bookmarks b
  JOIN moz_places p ON b.fk = p.id
  WHERE b.type = 1
  GROUP BY p.url
  HAVING duplicate_count > 1
  ORDER BY duplicate_count DESC
SQL
```

**Sample Output:**
```
Duplicate Bookmarks Found: 8
================================================================================

1. https://saleae.com/ (3 duplicates)
   Titles: Saleae | Saleae | Saleae Logic Analyzer

2. https://reactflow.dev/ (2 duplicates)
   Titles: React Flow | Node-Based UIs in React - React Flow

[... more duplicates ...]
```

## Workflow Examples

### Workflow 1: Bookmark Cleanup

**Scenario:** User wants to clean up old, unused bookmarks

**Steps:**
1. Find untagged bookmarks
2. Find bookmarks never visited
3. Find duplicates
4. Generate cleanup report

```ruby
# Step 1: Untagged bookmarks
untagged = db.execute(untagged_query)

# Step 2: Never visited
never_visited = db.execute(<<~SQL)
  SELECT p.url, b.title
  FROM moz_bookmarks b
  JOIN moz_places p ON b.fk = p.id
  WHERE b.type = 1
    AND (p.visit_count = 0 OR p.last_visit_date IS NULL)
SQL

# Step 3: Duplicates
duplicates = db.execute(duplicate_query)

# Generate report
puts "BOOKMARK CLEANUP REPORT"
puts "=" * 80
puts "\nUntagged: #{untagged.length}"
puts "Never visited: #{never_visited.length}"
puts "Duplicates: #{duplicates.length}"
puts "\nRecommendation: Review and remove #{untagged.length + never_visited.length} bookmarks"
```

### Workflow 2: Tag Organization Analysis

**Scenario:** User wants to reorganize tags

**Steps:**
1. List all tags by popularity
2. Find overlapping tags (similar names)
3. Suggest consolidation

```ruby
# Get all tags
tags = db.execute(<<~SQL)
  SELECT
    tag_folder.title as tag,
    COUNT(*) as count
  FROM moz_bookmarks tag_folder
  JOIN moz_bookmarks tagged_item ON tagged_item.parent = tag_folder.id
  WHERE tag_folder.parent = 4
  GROUP BY tag_folder.title
  ORDER BY count DESC
SQL

# Find potential duplicates (case-insensitive, similar names)
tag_names = tags.map { |t| t['tag'].downcase }
similar = tag_names.select { |t| tag_names.count { |n| n.include?(t) || t.include?(n) } > 1 }

puts "TAG ORGANIZATION SUGGESTIONS"
puts "=" * 80
puts "\nTotal tags: #{tags.length}"
puts "Tags used once: #{tags.count { |t| t['count'] == 1 }}"
puts "\nPotential duplicates to merge:"
similar.uniq.each { |tag| puts "  - #{tag}" }
```

### Workflow 3: Export Bookmarks to Markdown

**Scenario:** Export bookmarks grouped by tag to a Markdown file

```ruby
File.open("bookmarks_export.md", "w") do |f|
  f.puts "# Firefox Bookmarks Export"
  f.puts "Generated: #{Time.now.strftime('%Y-%m-%d %H:%M')}\n\n"

  # Get all tags
  tags = db.execute(tag_query)

  tags.each do |tag|
    f.puts "## #{tag['tag']} (#{tag['count']})\n\n"

    # Get bookmarks for this tag
    bookmarks = db.execute(bookmarks_by_tag_query, [tag['tag']])

    bookmarks.each do |bm|
      f.puts "- [#{bm['title']}](#{bm['url']})"
    end

    f.puts "\n"
  end
end

puts "Exported to bookmarks_export.md"
```

## Integration Examples

### Example 9: Generate Bookmark Report

**User Request:**
"Create a comprehensive bookmark report"

**Full Script:**
```ruby
#!/usr/bin/env ruby
require 'sqlite3'
require 'fileutils'

class BookmarkReport
  def initialize(db_path)
    @db = SQLite3::Database.new(db_path)
    @db.results_as_hash = true
  end

  def generate
    puts "FIREFOX BOOKMARKS REPORT"
    puts "=" * 80
    puts "Generated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    puts

    total_bookmarks
    recent_bookmarks
    tag_statistics
    visit_statistics
    cleanup_suggestions
  end

  def total_bookmarks
    count = @db.execute("SELECT COUNT(*) as count FROM moz_bookmarks WHERE type = 1")[0]['count']
    puts "Total Bookmarks: #{count}"
    puts
  end

  def recent_bookmarks
    recent = @db.execute(<<~SQL)
      SELECT COUNT(*) as count
      FROM moz_bookmarks
      WHERE type = 1
        AND dateAdded > (strftime('%s', 'now', '-30 days') * 1000000)
    SQL

    puts "Added in last 30 days: #{recent[0]['count']}"
    puts
  end

  def tag_statistics
    tags = @db.execute(<<~SQL)
      SELECT COUNT(DISTINCT tag_folder.id) as count
      FROM moz_bookmarks tag_folder
      WHERE tag_folder.parent = 4
    SQL

    puts "Total Tags: #{tags[0]['count']}"
    puts
  end

  def visit_statistics
    never_visited = @db.execute(<<~SQL)
      SELECT COUNT(*) as count
      FROM moz_bookmarks b
      JOIN moz_places p ON b.fk = p.id
      WHERE b.type = 1
        AND (p.visit_count = 0 OR p.last_visit_date IS NULL)
    SQL

    puts "Never Visited: #{never_visited[0]['count']}"
    puts
  end

  def cleanup_suggestions
    puts "Cleanup Suggestions:"
    puts "  - Review never-visited bookmarks"
    puts "  - Remove duplicate URLs"
    puts "  - Tag untagged bookmarks"
    puts
  end

  def close
    @db.close
  end
end

# Usage
profile_path = Dir.glob(File.expand_path("~/Library/Application Support/Firefox/Profiles/*default*")).first
places_db = File.join(profile_path, 'places.sqlite')
temp_db = "/tmp/places_report_#{Time.now.to_i}.sqlite"
FileUtils.cp(places_db, temp_db)

begin
  report = BookmarkReport.new(temp_db)
  report.generate
  report.close
ensure
  File.delete(temp_db)
end
```

## Troubleshooting Examples

### Issue: Script Can't Find Firefox Profile

**Error:**
```
Error: Firefox profiles directory not found
```

**Solution:**
```bash
# Manually locate Firefox profile
ls -la ~/Library/Application\ Support/Firefox/Profiles/

# Update script with correct path
profile = "/Users/alex/Library/Application Support/Firefox/Profiles/abc123.default-release"
```

### Issue: Database Locked

**Error:**
```
SQLite3::BusyException: database is locked
```

**Solution:**
All scripts create temporary copies, so this shouldn't happen. If it does:
1. Close Firefox
2. Wait a few seconds
3. Run script again

### Issue: Missing sqlite3 Gem

**Error:**
```
cannot load such file -- sqlite3
```

**Solution:**
```bash
gem install sqlite3 --user-install
```

For older Ruby versions:
```bash
gem install sqlite3 -v 1.4.4 --user-install
```

## Performance Tips

- Use LIMIT for large result sets
- Create indexes for frequent queries (read-only, so this doesn't apply)
- Filter early in WHERE clauses
- Use temporary database copies for safety

## Next Steps

After running these examples:
- Customize queries for your needs
- Build automation scripts
- Create bookmark management workflows
- Export data for backup or migration

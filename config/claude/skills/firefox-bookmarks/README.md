# Firefox Bookmarks Skill

A Claude Code skill for analyzing Firefox bookmarks directly from the places.sqlite database.

## Quick Start

### Extract Recent Bookmarks
```bash
ruby ~/.claude/skills/firefox-bookmarks/scripts/extract_bookmarks.rb [limit]
```

### Analyze Tags
```bash
ruby ~/.claude/skills/firefox-bookmarks/scripts/analyze_tags.rb
```

### Explore Database
```bash
ruby ~/.claude/skills/firefox-bookmarks/scripts/explore_db.rb
```

## What's Inside

- **SKILL.md** - Main skill instructions for Claude
- **REFERENCE.md** - Detailed database schema and SQL queries
- **EXAMPLES.md** - Practical usage examples and workflows
- **scripts/** - Ruby scripts for bookmark analysis
  - `extract_bookmarks.rb` - Extract recent bookmarks with metadata
  - `analyze_tags.rb` - Analyze tag popularity and usage
  - `explore_db.rb` - Explore Firefox database structure

## Features

- Extract bookmarks with URLs, titles, dates, and visit history
- Analyze bookmark tags and find most popular tags
- Cross-platform support (macOS, Linux, Windows)
- Safe read-only access using temporary database copies
- Automatic Firefox profile detection

## Requirements

- Ruby (system Ruby works fine)
- sqlite3 gem (pre-installed on most systems)
- Firefox with existing bookmarks

## How It Works

1. Automatically locates your Firefox profile
2. Creates a temporary copy of places.sqlite
3. Queries the database safely (read-only)
4. Cleans up temporary files automatically

## Database Structure

Firefox stores bookmarks in `places.sqlite`:

- **moz_bookmarks** - Bookmark hierarchy and folders
- **moz_places** - URL data and visit history
- **Tags** - Stored as folders under parent ID 4

## Common Use Cases

- Find your most recent bookmarks
- Analyze which tags you use most
- Find untagged bookmarks
- Detect duplicate URLs
- Export bookmarks to different formats
- Clean up old unused bookmarks

## Documentation

- [SKILL.md](SKILL.md) - Full skill documentation
- [REFERENCE.md](REFERENCE.md) - Technical reference
- [EXAMPLES.md](EXAMPLES.md) - Usage examples

## Safety

All scripts are read-only and use temporary database copies. Your original Firefox data is never modified.

## Support

For issues or questions, refer to:
- REFERENCE.md for database schema
- EXAMPLES.md for usage patterns
- Firefox Places Database documentation

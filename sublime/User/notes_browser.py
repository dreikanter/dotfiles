import sublime
import sublime_plugin
import os
import re

# Compile regular expressions at the module level
FRONTMATTER_PATTERN = re.compile(r'^---\s*\n(.*?)\n---', re.DOTALL)
TITLE_PATTERN = re.compile(r'^title:\s*(.*)', re.MULTILINE)

class NotesBrowserCommand(sublime_plugin.WindowCommand):
    def run(self):
        self.base_dir = self._base_dir()
        self.tag_files = self._collect_tags()
        self.tags = sorted(self.tag_files.keys())

        if not self.tags:
            sublime.message_dialog(f"No tags found in '{self.base_dir}'")
            return

        self.window.show_quick_panel(self.tags, self._on_tag_selected)

    def _collect_tags(self):
        tag_files = {}

        tags_pattern = re.compile(r'^tags:\s*\[(.*?)\]', re.MULTILINE)

        for root, _, files in os.walk(self.base_dir):
            for filename in files:
                if filename.endswith('.md'):
                    filepath = os.path.join(root, filename)

                    try:
                        with open(filepath, 'r', encoding='utf-8') as f:
                            content = f.read()
                    except Exception as e:
                        print(f"Error reading file {filepath}: {e}")
                        continue

                    frontmatter_match = FRONTMATTER_PATTERN.match(content)

                    if frontmatter_match:
                        frontmatter = frontmatter_match.group(1)
                        tags_match = tags_pattern.search(frontmatter)

                        if tags_match:
                            tags_str = tags_match.group(1)
                            tags = [tag.strip().strip("'\"") for tag in tags_str.split(',')]

                            for tag in tags:
                                if tag:
                                    tag_files.setdefault(tag, []).append(filepath)
        return tag_files

    def _on_tag_selected(self, index):
        if index == -1:
            return

        self.selected_tag = self.tags[index]
        files = self.tag_files[self.selected_tag]
        self.files = files

        display_files = []

        for f in files:
            file_path = os.path.relpath(f, self.base_dir)
            preview_text = self._get_preview_text(f)
            display_files.append([file_path, preview_text])

        self.window.show_quick_panel(
            display_files,
            self._on_file_selected
        )

    def _get_preview_text(self, filepath):
        try:
            with open(filepath, 'r', encoding='utf-8') as file_obj:
                content = file_obj.read()
                return self._extract_preview_text(content)
        except Exception as e:
            print(f"Error reading file {filepath}: {e}")
            return ''

    def _extract_preview_text(self, content):
        frontmatter_match = FRONTMATTER_PATTERN.match(content)

        if frontmatter_match:
            frontmatter = frontmatter_match.group(1)
            title = self._extract_title_from_frontmatter(frontmatter)

            if title:
                return title
            else:
                # No title in frontmatter, check for Markdown heading
                content_after_frontmatter = content[frontmatter_match.end():].lstrip('\n')
                heading = self._extract_heading(content_after_frontmatter)
                if heading:
                    return heading
        else:
            # No frontmatter, check for Markdown heading
            heading = self._extract_heading(content)

            if heading:
                return heading

        # Use a snippet from the beginning of the content
        snippet = content.strip().split('\n', 1)[0]
        return snippet

    def _extract_title_from_frontmatter(self, frontmatter):
        title_match = TITLE_PATTERN.search(frontmatter)

        if title_match:
            title = title_match.group(1).strip().strip("'\"")
            return title

        return ''

    def _extract_heading(self, content):
        lines = content.splitlines()

        for line in lines:
            stripped_line = line.strip()

            if stripped_line:
                if stripped_line.startswith('# '):
                    return stripped_line[2:].strip()
                elif stripped_line.startswith('#'):
                    return stripped_line.lstrip('#').strip()
                else:
                    return stripped_line

        return ''

    def _on_file_selected(self, index):
        if index == -1:
            return

        selected_file = self.files[index]
        self.window.open_file(selected_file)

    def _base_dir(self):
        return os.path.expanduser("~/Dropbox/Notes/")

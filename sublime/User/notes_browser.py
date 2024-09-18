import sublime
import sublime_plugin
import os
import re

class NotesBrowserCommand(sublime_plugin.WindowCommand):
    def run(self):
        self.base_dir = self._base_dir()
        self.tag_files = self._collect_tags()
        self.tags = sorted(self.tag_files.keys())

        if not self.tags:
            sublime.message_dialog("No tags found in '{}'".format(self.base_dir))
            return

        self.window.show_quick_panel(self.tags, self._on_tag_selected)

    def _collect_tags(self):
        tag_files = {}

        # Pattern to match YAML frontmatter
        frontmatter_pattern = re.compile(r'^---\s*\n(.*?)\n---', re.DOTALL)

        # Pattern to match the 'tags' field within the frontmatter
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

                    frontmatter_match = frontmatter_pattern.match(content)

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

        # Build display list with file previews
        display_files = []
        for f in files:
            file_path = os.path.relpath(f, self.base_dir)
            try:
                with open(f, 'r', encoding='utf-8') as file_obj:
                    # Read the first few lines to use as a preview
                    preview_lines = []
                    for _ in range(3):  # Adjust the number of lines as needed
                        line = file_obj.readline()
                        if not line:
                            break
                        line = line.strip()
                        if line:
                            preview_lines.append(line)
                    preview_text = ' '.join(preview_lines)
            except Exception as e:
                preview_text = ''
            display_files.append([file_path, preview_text])

        self.window.show_quick_panel(
            display_files,
            self._on_file_selected
        )

    def _on_file_selected(self, index):
        if index == -1:
            return

        selected_file = self.files[index]
        self.window.open_file(selected_file)

    def _base_dir(self):
        return os.path.expanduser("~/Dropbox/Notes/")

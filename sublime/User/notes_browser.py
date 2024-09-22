import sublime
import sublime_plugin
import os
import re

FRONTMATTER_PATTERN = re.compile(r'^---\s*\n(.*?)\n---', re.DOTALL)
TITLE_PATTERN = re.compile(r'^title:\s*(.*)', re.MULTILINE)
TAGS_PATTERN = re.compile(r'^tags:\s*\[(.*?)\]', re.MULTILINE)
FILENAME_PATTERN = re.compile(r'^\d+_(\d+)')
HEADING_PATTERN = re.compile(r'^#+\s+(.+)$')
SPECIAL_TAGS = ['ALL', 'UNTAGGED']

class NotesBrowserCommand(sublime_plugin.WindowCommand):
    def run(self):
        self.base_dir = self._base_dir()
        self.tags_index = self._build_index()
        self.tags = SPECIAL_TAGS + sorted(set(self.tags_index.keys()) - set(SPECIAL_TAGS))

        if not self.tags:
            sublime.message_dialog(f"No files found in '{self.base_dir}'")
            return

        self.window.show_quick_panel(self.tags, self._on_tag_selected)

    def _build_index(self):
        tags_index = {tag: [] for tag in SPECIAL_TAGS}

        for root, _, files in os.walk(self.base_dir):
            for filename in files:
                if filename.endswith('.md'):
                    path = os.path.join(root, filename)
                    file_info = self._read_file_info(path, filename)
                    if file_info:
                        self._add_to_index(tags_index, file_info)

        self._sort_index(tags_index)
        return tags_index

    def _read_file_info(self, path, filename):
        try:
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception as e:
            print(f"Error reading file {path}: {e}")
            return None

        return {
            'path': path,
            'content': content,
            'note_id': self._extract_note_id(filename)
        }

    def _add_to_index(self, tags_index, file_info):
        tags_index['ALL'].append(file_info)

        frontmatter_match = FRONTMATTER_PATTERN.match(file_info['content'])
        if frontmatter_match:
            frontmatter = frontmatter_match.group(1)
            tags = self._extract_tags(frontmatter)

            if tags:
                for tag in tags:
                    if tag:
                        tags_index.setdefault(tag, []).append(file_info)
            else:
                tags_index['UNTAGGED'].append(file_info)
        else:
            tags_index['UNTAGGED'].append(file_info)

    def _extract_tags(self, frontmatter):
        tags_match = TAGS_PATTERN.search(frontmatter)
        if tags_match:
            tags = [tag.strip().strip("'\"") for tag in tags_match.group(1).split(',')]
            return [tag for tag in tags if tag]
        return []

    def _sort_index(self, tags_index):
        for files in tags_index.values():
            files.sort(key=lambda x: x['note_id'], reverse=True)

    def _extract_note_id(self, filename):
        match = FILENAME_PATTERN.match(filename)

        if match:
            try:
                return int(match.group(1))
            except ValueError:
                print(f"Invalid unique number format in filename: {filename}")
        return -1

    def _on_tag_selected(self, index):
        if index == -1:
            return

        self.selected_tag = self.tags[index]
        files_info = self.tags_index[self.selected_tag]

        display_files_info = [
            {
                'path': file_info['path'],
                'name': self._get_base_file_name(file_info['path']),
                'preview': self._extract_preview(file_info['content']),
                'note_id': file_info['note_id']
            }
            for file_info in files_info
        ]

        display_files_info.sort(key=lambda x: x['note_id'], reverse=True)
        self.files_info = display_files_info
        display_files = [[info['name'], info['preview']] for info in display_files_info]

        self.window.show_quick_panel(display_files, self._on_file_selected)

    def _get_base_file_name(self, filepath):
        return os.path.splitext(os.path.basename(filepath))[0]

    def _extract_preview(self, content):
        frontmatter_match = FRONTMATTER_PATTERN.match(content)
        if frontmatter_match:
            frontmatter = frontmatter_match.group(1)
            title = self._extract_title_from_frontmatter(frontmatter)
            if title:
                return title
            content_after_frontmatter = content[frontmatter_match.end():].lstrip('\n')
            heading = self._extract_heading(content_after_frontmatter)
            if heading:
                return heading
        else:
            heading = self._extract_heading(content)
            if heading:
                return heading

        return content.strip().split('\n', 1)[0]

    def _extract_title_from_frontmatter(self, frontmatter):
        title_match = TITLE_PATTERN.search(frontmatter)
        return title_match.group(1).strip().strip("'\"") if title_match else ''

    def _extract_heading(self, content):
        for line in content.splitlines():
            stripped_line = line.strip()
            if stripped_line:
                heading_match = HEADING_PATTERN.match(stripped_line)
                if heading_match:
                    return heading_match.group(1)
                return stripped_line
        return ''

    def _on_file_selected(self, index):
        if index != -1:
            self.window.open_file(self.files_info[index]['path'])

    def _base_dir(self):
        return os.path.expanduser("~/Dropbox/Notes/")

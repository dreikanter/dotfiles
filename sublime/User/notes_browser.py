import sublime
import sublime_plugin
import os
import re

FRONTMATTER_PATTERN = re.compile(r'^---\s*\n(.*?)\n---', re.DOTALL)
TITLE_PATTERN = re.compile(r'^title:\s*(.*)', re.MULTILINE)
TAGS_PATTERN = re.compile(r'^tags:\s*\[(.*?)\]', re.MULTILINE)
FILENAME_PATTERN = re.compile(r'^\d+_(\d+)')
SPECIAL_TAGS = ['ALL', 'UNTAGGED']

class NotesBrowserCommand(sublime_plugin.WindowCommand):
    def run(self):
        self.base_dir = self._base_dir()
        self.tags_index = self._build_index()
        self.tags = SPECIAL_TAGS + sorted(tag for tag in self.tags_index.keys() if tag not in SPECIAL_TAGS)

        if not self.tags:
            sublime.message_dialog(f"No files found in '{self.base_dir}'")
            return

        self.window.show_quick_panel(self.tags, self._on_tag_selected)

    def _build_index(self):
        tags_index = {tag: [] for tag in SPECIAL_TAGS}

        for root, _, files in os.walk(self.base_dir):
            for filename in files:
                if not filename.endswith('.md'):
                    continue

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

        note_id = self._extract_note_id(filename)

        return {
            'path': path,
            'content': content,
            'note_id': note_id
        }

    def _add_to_index(self, tags_index, file_info):
        tags_index['ALL'].append(file_info)

        frontmatter_match = FRONTMATTER_PATTERN.match(file_info['content'])
        if frontmatter_match:
            frontmatter = frontmatter_match.group(1)
            tags = self._extract_tags(frontmatter)

            if tags:
                for tag in tags:
                    tags_index.setdefault(tag, []).append(file_info)
            else:
                tags_index['UNTAGGED'].append(file_info)
        else:
            tags_index['UNTAGGED'].append(file_info)

    def _extract_tags(self, frontmatter):
        tags_match = TAGS_PATTERN.search(frontmatter)
        if tags_match:
            tags_str = tags_match.group(1)
            return [tag.strip().strip("'\"") for tag in tags_str.split(',') if tag.strip()]
        return []

    def _sort_index(self, tags_index):
        for tag in tags_index:
            tags_index[tag].sort(key=lambda x: x['note_id'], reverse=True)

    def _extract_note_id(self, filename):
        match = FILENAME_PATTERN.match(filename)

        if match:
            note_id_str = match.group(1)
            try:
                return int(note_id_str)
            except ValueError:
                print(f"Invalid unique number format in filename: {filename}")

        return -1  # Return -1 if no valid unique number found

    def _on_tag_selected(self, index):
        if index == -1:
            return

        self.selected_tag = self.tags[index]
        files_info = self.tags_index[self.selected_tag]

        display_files_info = []

        for file_info in files_info:
            base_name = self._get_base_file_name(file_info['path'])
            preview = self._extract_preview(file_info['content'])

            display_files_info.append({
                'path': file_info['path'],
                'name': base_name,
                'preview': preview,
                'note_id': file_info['note_id']
            })

        display_files_info.sort(key=lambda x: x['note_id'], reverse=True)
        self.files_info = display_files_info
        display_files = [[info['name'], info['preview']] for info in display_files_info]

        self.window.show_quick_panel(
            display_files,
            self._on_file_selected
        )

    def _get_base_file_name(self, filepath):
        return os.path.splitext(os.path.basename(filepath))[0]

    def _extract_preview(self, content):
        frontmatter_match = FRONTMATTER_PATTERN.match(content)

        if frontmatter_match:
            frontmatter = frontmatter_match.group(1)
            title = self._extract_title_from_frontmatter(frontmatter)

            if title:
                return title
            else:
                content_after_frontmatter = content[frontmatter_match.end():].lstrip('\n')
                heading = self._extract_heading(content_after_frontmatter)
                if heading:
                    return heading
        else:
            heading = self._extract_heading(content)

            if heading:
                return heading

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

        selected_file = self.files_info[index]['path']
        self.window.open_file(selected_file)

    def _base_dir(self):
        return os.path.expanduser("~/Dropbox/Notes/")

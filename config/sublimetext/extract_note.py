import sublime
import sublime_plugin
import os
import json
from datetime import datetime
import re

class ExtractNoteCommand(sublime_plugin.TextCommand):
    LAST_ID_KEY = 'last_id'

    def run(self, edit):
        for region in self.view.sel():
            if region.empty():
                self._process_line(edit, region)

        sublime.set_timeout(lambda: self.view.run_command('save'), 0)

    def _extract_note_id_from_filename(self, filename):
        if not filename:
            return "unknown"

        match = re.match(r'(\d+_\d+).*', os.path.basename(filename))
        return match.group(1) if match else "unknown"

    def _process_line(self, edit, region):
        date = self._current_date()
        note_id = self._get_new_note_id()
        new_note_file = self._get_new_file_path(date, note_id)
        original_file = self.view.file_name()
        original_note_id = self._extract_note_id_from_filename(original_file)

        line = self.view.line(region)
        line_content = self.view.substr(line)
        self.view.replace(edit, line, f"{line_content} // *{date}_{note_id}*")

        with open(new_note_file, 'w', encoding='utf-8') as f:
            f.write("---\n")
            f.write(f"origin: {original_note_id}\n")
            f.write("---\n\n")
            f.write(f"{line_content}\n")

        self.view.window().open_file(new_note_file)

    def _get_new_file_path(self, date, note_id):
        year = date[:4]
        month = date[4:6]
        subdirectory_path = os.path.join(self._get_notes_path(), year, month)
        os.makedirs(subdirectory_path, exist_ok=True)

        return os.path.join(subdirectory_path, f'{date}_{note_id}.md')

    def _current_date(self):
        if not hasattr(self, '_cached_current_date'):
            self._cached_current_date = datetime.now().strftime('%Y%m%d')
        return self._cached_current_date

    def _get_new_note_id(self):
        id_file = self._id_file_path()

        try:
            if os.path.exists(id_file):
                with open(id_file, 'r') as f:
                    data = json.load(f)
                    current_id = data.get(self.LAST_ID_KEY, 0)
            else:
                current_id = 0

            new_id = current_id + 1
            with open(id_file, 'w') as f:
                json.dump({self.LAST_ID_KEY: new_id}, f)

            return new_id

        except Exception as e:
            sublime.status_message(f"Error handling ID file ('{id_file}'): {str(e)}")
            return 0

    def _id_file_path(self):
        return os.path.join(self._get_notes_path(), 'id.json')

    def _get_notes_path(self):
        current_file = os.path.basename(__file__)
        settings = sublime.load_settings(current_file.replace('.py', '.sublime-settings'))
        return os.path.expanduser(settings.get('notes_path', '~/Dropbox/Notes'))

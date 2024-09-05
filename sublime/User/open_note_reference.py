import sublime
import sublime_plugin
import os
import re
from datetime import datetime

class OpenNoteReferenceCommand(sublime_plugin.TextCommand):
    REFERENCE_PATTERN = r'^\d{8}_[a-zA-Z0-9_-]+?$'
    DATE_PATTERN = r'^\d{8,}(_[a-zA-Z0-9_-]+)?$'

    def run(self, edit):
        for region in self.view.sel():
            word = self.view.word(region) if region.empty() else region
            selected_word = self.view.substr(word)

            if not re.match(self.REFERENCE_PATTERN, selected_word):
                print(f"selected word is not a note reference: '{selected_word}'")
                continue

            reference = selected_word.strip('[]')

            referenced_file = self._find_referenced_file(reference)

            if referenced_file:
                print(f"opening note reference: {reference} -> {referenced_file}")
                self.view.window().open_file(referenced_file)
            else:
                sublime.status_message(f"referenced note not found: {reference}")

    def _find_referenced_file(self, reference):
        root_path = self._notes_root_path()

        if not root_path:
            return

        if re.match(self.DATE_PATTERN, reference):
            year, month, day = reference[:4], reference[4:2], reference[6:2]
            search_dir = os.path.join(root_path, year, month)
        else:
            search_dir = root_path

        for root, dirs, files in os.walk(search_dir):
            for file in files:
                if file.endswith(".md"):
                    if reference in file:
                        return os.path.join(root, file)

        return None

    def _notes_root_path(self):
        current_file = self.view.file_name()

        if not current_file:
            sublime.error_message("Please save the file first.")
            return

        return os.path.expanduser("~/Dropbox/Notes/")

def plugin_loaded():
    sublime.status_message("Referenced Note Opener plugin loaded")

def plugin_unloaded():
    sublime.status_message("Referenced Note Opener plugin unloaded")

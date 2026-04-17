import sublime
import sublime_plugin
import os
import re

FULL_FILENAME_PATTERN = re.compile(r'^(\d{8}_\d+)(?:_[a-zA-Z0-9_-]+)?\.md$')
SHORT_FILENAME_PATTERN = re.compile(r'^\d{8}_(\d+)(?:_[a-zA-Z0-9_-]+)?\.md$')


class CopyNoteLinkCommand(sublime_plugin.TextCommand):
    def run(self, edit):
        link = self._build_link()
        if link:
            sublime.set_clipboard(link)
            sublime.status_message(f"Copied: {link}")
        else:
            sublime.status_message("Current file is not a note")

    def _build_link(self):
        path = self.view.file_name()
        if not path:
            return None
        match = FULL_FILENAME_PATTERN.match(os.path.basename(path))
        return f"note://{match.group(1)}" if match else None


class CopyShortNoteLinkCommand(sublime_plugin.TextCommand):
    def run(self, edit):
        link = self._build_link()
        if link:
            sublime.set_clipboard(link)
            sublime.status_message(f"Copied: {link}")
        else:
            sublime.status_message("Current file is not a note")

    def _build_link(self):
        path = self.view.file_name()
        if not path:
            return None
        match = SHORT_FILENAME_PATTERN.match(os.path.basename(path))
        return f"note://{match.group(1)}" if match else None

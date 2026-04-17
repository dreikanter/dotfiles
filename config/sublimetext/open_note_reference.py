import sublime
import sublime_plugin
import os
import re

TOKEN_PATTERN = re.compile(r'(note://)?([\w-]+)')
FULL_ID_PATTERN = re.compile(r'^(\d{8}_\d+)(?:_[a-zA-Z0-9_-]+)?$')
SHORT_ID_PATTERN = re.compile(r'^\d+$')
FILENAME_FULL_PATTERN = re.compile(r'^(\d{8}_\d+)(?:_[a-zA-Z0-9_-]+)?\.md$')
FILENAME_SHORT_PATTERN = re.compile(r'^\d{8}_(\d+)(?:_[a-zA-Z0-9_-]+)?\.md$')

NOTES_ROOT = "~/Dropbox/Notes/"


class OpenNoteReferenceCommand(sublime_plugin.TextCommand):
    def run(self, edit):
        for region in self.view.sel():
            token = self._extract_token(region)
            if not token:
                continue

            has_scheme, ident = token
            referenced_file = self._find_referenced_file(has_scheme, ident)

            if referenced_file:
                print(f"opening note reference: {ident} -> {referenced_file}")
                self.view.window().open_file(referenced_file)
            else:
                sublime.status_message(f"referenced note not found: {ident}")

    def _extract_token(self, region):
        if not region.empty():
            raw = self.view.substr(region).strip().strip("[]")
            scheme_match = TOKEN_PATTERN.fullmatch(raw)
            if scheme_match:
                return (scheme_match.group(1) is not None, scheme_match.group(2))
            return None

        line_region = self.view.line(region)
        line_text = self.view.substr(line_region)
        cursor_col = region.begin() - line_region.begin()

        for match in TOKEN_PATTERN.finditer(line_text):
            if match.start() <= cursor_col <= match.end():
                return (match.group(1) is not None, match.group(2))
        return None

    def _find_referenced_file(self, has_scheme, ident):
        root_path = self._notes_root_path()
        if not root_path:
            return None

        full = FULL_ID_PATTERN.match(ident)
        if full:
            prefix = full.group(1)
            for root, _, files in os.walk(root_path):
                for name in files:
                    if name.startswith(prefix) and FILENAME_FULL_PATTERN.match(name):
                        return os.path.join(root, name)
            return None

        if has_scheme and SHORT_ID_PATTERN.match(ident):
            for root, _, files in os.walk(root_path):
                for name in files:
                    match = FILENAME_SHORT_PATTERN.match(name)
                    if match and match.group(1) == ident:
                        return os.path.join(root, name)
            return None

        return None

    def _notes_root_path(self):
        current_file = self.view.file_name()
        if not current_file:
            sublime.error_message("Please save the file first.")
            return None
        return os.path.expanduser(NOTES_ROOT)


def plugin_loaded():
    sublime.status_message("Referenced Note Opener plugin loaded")


def plugin_unloaded():
    sublime.status_message("Referenced Note Opener plugin unloaded")

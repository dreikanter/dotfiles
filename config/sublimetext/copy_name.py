import sublime
import sublime_plugin
import os

class CopyNameCommand(sublime_plugin.TextCommand):
    def run(self, edit):
        file_path = self.view.file_name()
        if file_path:
            file_name = os.path.basename(file_path)
            name_without_extension = os.path.splitext(file_name)[0]
            sublime.set_clipboard(name_without_extension)
            sublime.status_message(f"Copied: {name_without_extension}")
        else:
            sublime.status_message("No file open")

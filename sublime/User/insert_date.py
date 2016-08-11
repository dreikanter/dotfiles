import datetime
import sublime_plugin


class InsertDateCommand(sublime_plugin.TextCommand):
    def run(self, edit):
        timestamp_str = datetime.datetime.now().strftime("%Y-%m-%d:\n\n")
        for r in self.view.sel():
            self.view.insert(edit, r.begin(), timestamp_str)

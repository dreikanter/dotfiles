import sublime
import sublime_plugin


class InsertLineNumbersCommand(sublime_plugin.TextCommand):
    def run(self, edit):
        selected_region = self.view.sel()[0]
        if selected_region.size() == 0:
            text = self.view.substr(sublime.Region(0, self.view.size()))
        else:
            text = self.view.substr(sublime.Region(selected_region.begin(), selected_region.end()))
        lines = text.split("\n")
        text = ""
        for idx, val in enumerate(lines):
            text = text + str(idx + 1) + ". " + val + "\n"
        if selected_region.size() == 0:
            self.view.replace(edit, sublime.Region(0, self.view.size()), text)
        else:
            self.view.replace(edit, sublime.Region(selected_region.begin(), selected_region.end()), text)

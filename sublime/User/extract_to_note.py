import sublime
import sublime_plugin


class ExtractToNoteCommand(sublime_plugin.TextCommand):
  def run(self, edit):
    # self.view.insert(edit, 0, "Hello, World!")

    settings = sublime.load_settings('ProcessLine.sublime-settings')
    command = settings.get('command', ['cat'])
    print("Command: ", command)

    self.view.run_command('save')

    # Get the current line content
    for region in self.view.sel():
      if region.empty():
        line = self.view.line(region)
        line_text = self.view.substr(line)

        # Execute command and get output
        process = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        output, error = process.communicate(input=line_text)

        if process.returncode == 0:
          # Replace the line with output
          self.view.replace(edit, line, output)
        else:
          sublime.error_message("Error: " + str(error))

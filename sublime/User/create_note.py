import sublime
import sublime_plugin
import os
import datetime

NOTES_PATH = os.path.expanduser("~/Dropbox/Notes/")
ID_PATH = os.path.join(NOTES_PATH, "id.txt")

class CreateNoteCommand(sublime_plugin.WindowCommand):
    def run(self):
        file_name = self.new_note_path()
        print(file_name)
        os.makedirs(os.path.dirname(file_name), exist_ok=True)
        self.window.run_command("new_file")
        self.window.active_view().set_name(os.path.basename(file_name))
        self.window.active_view().set_scratch(True)
        self.window.run_command("save", {"file": file_name})
        self.window.open_file(file_name)

    def new_note_path(self):
        now = datetime.datetime.now()
        return os.path.join(
            NOTES_PATH,
            now.strftime("%Y"),
            now.strftime("%m"),
            f"{now.strftime('%Y%m%d')}_{self.generate_new_id()}.md"
        )

    def generate_new_id(self):
        last_id = self.last_id()
        new_id = last_id + 1
        with open(ID_PATH, 'w') as f:
            f.write(str(new_id))
        return new_id

    def last_id(self):
        try:
            with open(ID_PATH, 'r') as f:
                return int(f.read().strip())
        except Exception:
            return len([f for f in os.walk(NOTES_PATH) for file in f[2] if file.endswith('.md')])

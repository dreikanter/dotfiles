import sublime
import sublime_plugin
import os
import shutil
import subprocess


def _notes_binary():
    gopath = os.environ.get('GOPATH') or os.path.expanduser('~/go')
    candidate = os.path.join(gopath, 'bin', 'notes')
    if os.path.isfile(candidate) and os.access(candidate, os.X_OK):
        return candidate
    return shutil.which('notes')


def _run_notes(args):
    binary = _notes_binary()
    if not binary:
        sublime.error_message("'notes' CLI not found. Install it first.")
        return None

    env = os.environ.copy()
    env['PATH'] = env.get('PATH', '') + ':/opt/homebrew/bin:/usr/local/bin'

    try:
        result = subprocess.run(
            [binary] + args,
            capture_output=True,
            text=True,
            env=env,
            check=True,
        )
    except subprocess.CalledProcessError as e:
        sublime.error_message(f"notes {' '.join(args)} failed:\n{e.stderr.strip() or e.stdout.strip()}")
        return None

    path = result.stdout.strip()
    if not path:
        sublime.error_message(f"notes {' '.join(args)} returned no path")
        return None
    return path


class NewNoteCommand(sublime_plugin.WindowCommand):
    def run(self):
        path = _run_notes(['new'])
        if path:
            self.window.open_file(f"{path}:999999:1", sublime.ENCODED_POSITION)


class NewTodoCommand(sublime_plugin.WindowCommand):
    def run(self):
        path = _run_notes(['new-todo'])
        if path:
            self.window.open_file(f"{path}:999999:1", sublime.ENCODED_POSITION)

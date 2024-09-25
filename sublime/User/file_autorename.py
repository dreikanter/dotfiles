import sublime
import sublime_plugin

import os
import re
import unicodedata


class FileAutorenameCommand(sublime_plugin.TextCommand):
    """
    Extract "slug" value from YAML frontmatter in the current tab, and rename
    the file, while preserving numeric prefix (note UID).

    Example:

    Original file name: 20230826_1234.md

    Frontmatter:
        ---
        slug: sample-slug
        ---

    New file name: 20230826_1234_sample-slug.md
    """
    FRONTMATTER_REGEX = re.compile(r'^---\s*$(.*?)^---\s*$', re.DOTALL | re.MULTILINE)
    SLUG_REGEX = re.compile(r"^slug:\s*(.*?)$", re.MULTILINE)

    def run(self, edit):
        original_filename = self.view.file_name()

        if not original_filename:
                return

        if not os.access(original_filename, os.W_OK):
            return self._status_error(f"File is read-only: {original_filename}")

        dirname, basename = os.path.split(original_filename)
        basename, extension = os.path.splitext(basename)
        uid = self._extract_uid(basename)

        if not uid:
            return self._status_error("File name is missing UID")

        text = self.view.substr(sublime.Region(0, self.view.size()))
        extracted_slug = self._extract_slug(text)

        if extracted_slug is None:
                return self._status_error("Missing or empty slug in frontmatter")

        slug = self._slugify(extracted_slug)
        new_filename = f"{dirname}/{uid}_{slug}{extension}" if slug else f"{dirname}/{uid}{extension}"

        if original_filename == new_filename:
            return self._status(f"Name unchanged: {new_filename}")

        if os.path.exists(new_filename):
            return self._status_error(f"File already exists: {new_filename}")

        try:
            os.rename(original_filename, new_filename)
        except OSError as e:
            return self._status_error(f"Unable to rename: {str(e)}")

        self.view.retarget(new_filename)
        self._status(f"New name: {new_filename}")

    def _slugify(self, value):
        """Normalize slug value, e.g. " Sample slug! " -> "sample-slug"""
        value = unicodedata.normalize("NFKD", value).encode("ascii", "ignore").decode("ascii")
        value = re.sub(r"[^\w\s-]", "", value).strip().lower()
        return re.sub(r"[-\s]+", "-", value)

    def _extract_slug(self, text):
        """Parse YAML fragment and extract "slug" value"""
        frontmatter = self.FRONTMATTER_REGEX.search(text)
        if not frontmatter:
            return ""
        yaml = frontmatter.group(1)
        slug_match = self.SLUG_REGEX.search(yaml)
        if slug_match:
            return slug_match.group(1).strip()
        return ""

    def _extract_uid(self, basename):
        """Extract UID from a file name. Example: 20230826_1234_slug.md -> 20230826_1234"""
        try:
            return re.match(r"^(\d+_\d+)", basename).group(1)
        except AttributeError:
            return None

    def _status_error(self, message):
        """Show an error message in the status bar"""
        self._status(f"[ERROR] {message}")

    def _status(self, message):
        """Show a message in the status bar"""
        sublime.status_message(message)

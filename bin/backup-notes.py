from datetime import datetime
import os

NOTES_PATH = 'd:\\dropbox\\notes\\*'
DEST_PATH = 'd:\\dropbox\\backup'

prefix = datetime.now().strftime("%Y%m%d_%H%M")
archive_file = os.path.join(DEST_PATH, "%s-notes" % prefix)

command = "d:\\bin\\7za a -tzip -mx9 -x!*.bak \"%s\"  \"%s\""
command = command % (archive_file, NOTES_PATH)

print(command)
os.system(command)

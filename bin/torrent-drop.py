import os
import sys

DEST = '\\\\192.168.1.110\\new-torrents'

for file_name in sys.argv[1:]:
    cmd = "move /y \"%s\" \"%s\"" % (file_name, DEST)
    print(cmd)
    os.system(cmd)

# try:
#     sys.stdin.read(1)
# except:
#     pass

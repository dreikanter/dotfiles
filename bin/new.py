#!/usr/bin/env python
# coding: utf-8

"""A script to create new file with a date-based name."""

import argparse
import os.path
from datetime import datetime

DEFAULT_NAME = "{date:%Y%m%d-%H%M}{suffix}.things"  # Default name pattern for a new file
DEFAULT_EDITOR = 'subl'  # Default path to the editor executable
HEADER_FORMAT = "{date:%Y-%m-%d}:\n\n"


def makedirs(dir_path):
    if dir_path and not os.path.exists(dir_path):
        os.makedirs(dir_path)
        return True
    return False


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--name',
                        type=str,
                        default=DEFAULT_NAME,
                        help='name pattern for a new file')
    parser.add_argument('--editor',
                        type=str,
                        default=DEFAULT_EDITOR,
                        help='path to the editor executable')
    parser.add_argument('--open',
                        action='store_true',
                        help='open in the editor')
    args = parser.parse_args()
    return args.name, args.editor, args.open


name, editor, open_editor = parse_args()

ts = datetime.now()
suffix = 0
while True:
    file_name = name.format(date=ts, suffix=("-%d" % suffix if suffix else ''))
    suffix = suffix + 1
    if not os.path.exists(file_name):
        break

file_name = os.path.abspath(file_name)
with open(file_name, mode='w') as f:
    f.write(HEADER_FORMAT.format(date=ts))
os.system("\"%s\" %s" % (editor, file_name))

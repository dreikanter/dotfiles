#!/usr/bin/env python
# coding: utf-8

"""A script to rename image.* to YYYYMMDD-image.*.
Use --help for command line options help."""

import argparse
import glob
import os.path
from datetime import datetime
import re
import shutil

SOURCE_PATH = 'source'  # Relative path to the image inbox (base path is the script location)
DEST_PATH = 'images'  # Relative path to store renamed images
EXTENSIONS = ['.jpg', '.jpeg', '.gif', '.png', '.bmp', '.tiff', '.svg']
RE_FLAGS = re.I | re.M | re.U
URI_SEP_PATTERN = re.compile(r"[^a-z\d\%s]+" % os.sep, RE_FLAGS)
URI_EXCLUDE_PATTERN = re.compile(r"[,.`\'\"\!@\#\$\%\^\&\*\(\)\+]+", RE_FLAGS)


def makedirs(dir_path):
    if dir_path and not os.path.exists(dir_path):
        os.makedirs(dir_path)
        return True
    return False


def walk(path, operation, dry_run):
    for file_name in glob.glob(os.path.join(path, '*')):
        if not os.path.isdir(file_name):
            process_image(file_name, dry_run)


def urlify(string):
    result = URI_EXCLUDE_PATTERN.sub('', string)
    if os.altsep:
        result = result.replace(os.altsep, os.sep)
    result = URI_SEP_PATTERN.sub('-', result)
    return result.strip('-').lower()


def process_image(file_name, dry_run=False):
    basename, ext = os.path.splitext(os.path.basename(file_name))
    ext = ext.lower()
    if ext in EXTENSIONS:
        basename = urlify(basename)
        ts = datetime.fromtimestamp(os.path.getctime(file_name))
        dest = "%s-%s%s" % (ts.strftime("%Y%m%d%H%M"), basename, ext)
        print(" - %s" % dest)
        if not dry_run:
            shutil.move(file_name, os.path.join(DEST_PATH, dest))


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source',
                        type=str,
                        default=SOURCE_PATH,
                        help='images source directory path')
    parser.add_argument('--dest',
                        type=str,
                        default=DEST_PATH,
                        help='destination directory path')
    parser.add_argument('--dryrun',
                        action='store_true',
                        help='do a dry run')
    args = parser.parse_args()
    return args.source, args.dest, args.dryrun


base_path = os.path.dirname(__file__)
source_path, dest_path, dryrun = parse_args()
source_path = os.path.abspath(os.path.join(base_path, source_path))
dest_path = os.path.abspath(os.path.join(base_path, dest_path))

print("source: %s" % source_path)
if not dryrun:
    makedirs(source_path)

print("destination: %s" % dest_path)
if not dryrun:
    makedirs(dest_path)

walk(source_path, process_image, dryrun)

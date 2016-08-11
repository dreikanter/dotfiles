#!/usr/bin/env python
# coding: utf-8

"""Dropbox shared files backup tool"""

import argparse
from datetime import datetime
import glob
import logging
import os.path
import shutil


def parse_args():
    parser = argparse.ArgumentParser(description='dropbox shared files backup tool')
    parser.add_argument('source',
                        metavar='<source/path>',
                        type=str,
                        help='source directory location')
    parser.add_argument('dest',
                        metavar='<backup/path>',
                        type=str,
                        help='backup path; year/month-based dir structure could be used')
    parser.add_argument('-d', '--dry',
                        action='store_true',
                        help='dry run')
    parser.add_argument('-l', '--log',
                        default=os.path.splitext(__file__)[0] + '.log',
                        help='log file name')
    args = parser.parse_args()
    return args.source, args.dest, args.dry, args.log


source_path, backup_path, dryrun, log_file = parse_args()

log = logging.getLogger()
log.setLevel(logging.DEBUG)
for ch in [logging.StreamHandler(), logging.FileHandler(log_file, encoding='utf8')]:
    ch.setLevel(logging.DEBUG)
    ch.setFormatter(logging.Formatter("%(asctime)s %(levelname)s: %(message)s",
                                      "%Y/%m/%d %H:%M:%S"))
    log.addHandler(ch)

if not os.path.isdir(source_path):
    log.error("source path not exists or not accessible: '%s'" % source_path)
    exit()

log.info("source path: '%s'" % source_path)

if dryrun:
    log.info('dry run mode enabled')

for file_name in glob.glob(os.path.join(source_path, '*')):
    if os.path.isdir(file_name):
        subdir_name = os.path.basename(file_name)
        subdir_date = datetime.fromtimestamp(os.path.getctime(file_name))
        date_path = subdir_date.strftime(backup_path)
        dest_path = os.path.join(date_path, subdir_name)

        if os.path.exists(dest_path):
            log.info("skipping '%s'" % subdir_name)
            continue

        log.info("copying '%s' to '%s'" % (subdir_name, dest_path))

        if dryrun:
            continue

        try:
            shutil.copytree(file_name, dest_path)
        except Exception as e:
            log.error(str(e))

log.info('done')

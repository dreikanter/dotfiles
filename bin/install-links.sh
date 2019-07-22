#!/usr/bin/env bash

set -x

for symlink in $(cat ./links.txt)
do
  ln -sf $PWD/../$symlink ~/.$symlink
done

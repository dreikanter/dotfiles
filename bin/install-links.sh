#!/usr/bin/env bash

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

for symlink in $(cat $SCRIPTPATH/links.txt)
do
  echo $symlink
  ln -sf $SCRIPTPATH/../$symlink ~/.$symlink
done

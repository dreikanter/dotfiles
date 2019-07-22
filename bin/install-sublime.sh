#!/usr/bin/env bash

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
USER_DIR=~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User

if [ -d "$USER_DIR" ]; then
  if [ -L "$USER_DIR" ]; then
    echo 'Removing existing Sublime user directory link'
    rm "$USER_DIR"
  else
    echo 'Removing existing Sublime user directory'
    rmdir "$USER_DIR"
  fi
fi

ln -sf $SCRIPTPATH/../sublime/User "$USER_DIR"

#!/usr/bin/env bash

USER_DIR=~/Library/Application\ Support/Sublime\ Text/Packages/User

if [ -d "$USER_DIR" ]; then
  if [ -L "$USER_DIR" ]; then
    echo 'Removing existing Sublime user directory link'
    rm "$USER_DIR"
  else
    echo 'Removing existing Sublime user directory'
    rmdir "$USER_DIR"
  fi
fi

ln -sf ~/.dotfiles/sublime/User "$USER_DIR"


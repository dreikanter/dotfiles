#!/usr/bin/env bash

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

touch ~/.profile

~/.dotfiles/bin/install/homebrew.sh
~/.dotfiles/bin/install/links.sh
~/.dotfiles/bin/install/sublime.sh
~/.dotfiles/bin/install/macos-defaults.sh

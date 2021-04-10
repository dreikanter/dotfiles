#!/usr/bin/env bash

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

find ~/.dotfiles/install-*.sh -type f -exec bash {} \;

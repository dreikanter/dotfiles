#!/usr/bin/env bash

[ -f "$HOME/.zshenv" ] && source "$HOME/.zshenv"
exec "$HOME/.dotfiles/bin/latest-note"

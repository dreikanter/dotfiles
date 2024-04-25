#!/usr/bin/env bash

mkdir -p ~/.config

ln -sf ~/.dotfiles/editorconfig ~/.editorconfig
ln -sf ~/.dotfiles/gitconfig ~/.gitconfig
ln -sf ~/.dotfiles/gitignore_global ~/.gitignore_global
ln -sf ~/.dotfiles/zshrc ~/.zshrc
ln -sf ~/.dotfiles/bin ~/bin
ln -sf ~/.dotfiles/config/nvim ~/.config/nvim

mkdir -p ~/.config/wezterm
ln -sf ~/.dotfiles/config/wezterm/wezterm.lua ~/.config/wezterm/wezterm.lua

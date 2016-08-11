#!/usr/bin/sh

# Install dotfiles to user directory

for symlink in .{aliases,editorconfig,exports,gitconfig,zshrc,vimrc,vimrc.bundles,gitignore_global}
do
    rm ~/$symlink
    ln -s $PWD/$symlink ~/$symlink
done

# Install Sublime Text settings

USER_DIR=~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User

if [ -d "$USER_DIR" ]; then
  if [ -L "$USER_DIR" ]; then
    rm "$USER_DIR"  # Removing existing link
  else
    rmdir "$LINK_OR_DIR"  # Removing existing directory
  fi
fi

ln -sf ~/.dotfiles/sublime/User "$USER_DIR"

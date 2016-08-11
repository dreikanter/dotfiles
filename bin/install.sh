#!/usr/bin/sh

echo --> Install dotfiles to user directory

for symlink in {aliases,editorconfig,exports,gitconfig,zshrc,vimrc,vimrc.bundles,gitignore_global}
do
  echo Linking ~/.$symlink
  rm ~/.$symlink
  ln -s $PWD/$symlink ~/.$symlink
done

echo --> Install Sublime Text settings

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

ln -sf $PWD/sublime/User "$USER_DIR"

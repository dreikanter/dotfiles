# Alex's dotfiles

Initial setup:

``` bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install git
git clone git@github.com:dreikanter/dotfiles.git ~/.dotfiles
bash ~/.dotfiles/bin/dotfiles load
ln -sf ~/.dotfiles/bin ~/bin
```

Install homebrew packages:

```
brew bundle --file=~/.dotfiles/Brewfile
```

## Global hotkeys

- `Ctrl+Shift+N` – create new note.
- `Ctrl+Shift+L` – open the latest note.
- `Ctrl+Shift+T` – open the latest todo note.

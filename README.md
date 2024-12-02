# Alex's dotfiles

Initial setup:

``` bash
git clone git@github.com:dreikanter/dotfiles.git ~/.dotfiles
bash ~/.dotfiles/install/all.sh
```

Install homebrew packages:

```
brew bundle --file=~/.dotfiles/Brewfile
```

## Setup tips

iTerm:

- Enable patched font: iTerm2 → Preferences → Profiles → Font

## Global hotkeys

- `Ctrl+Shift+N` – create new note.
- `Ctrl+Shift+L` – open the latest note.
- `Ctrl+Shift+T` – open the latest todo note.

## Maintenance

Update `Brewfile`:

```
brew bundle dump --force --file=~/.dotfiles/Brewfile
```


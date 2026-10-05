# Alex's dotfiles

Initial setup:

``` bash
bash <(curl -fsSL https://raw.githubusercontent.com/dreikanter/dotfiles/master/setup)
```

Install homebrew packages:

```
brew bundle --file=~/.dotfiles/Brewfile
```

## Global hotkeys

- `Ctrl+Shift+N` – create new note.
- `Ctrl+Shift+L` – open the latest note.
- `Ctrl+Shift+T` – open the latest todo note.

## Karabiner keyboard mapping

For this setup, keep **Virtual Keyboard → ANSI** and enable **Devices → Swap ISO
specific keys** for each keyboard. This fixes the §/± key to the left of 1 so
Cmd + that key switches windows using the native macOS shortcut.

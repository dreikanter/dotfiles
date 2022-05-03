# Fig pre block. Keep at the top of this file.
. "$HOME/.fig/shell/zshrc.pre.zsh"
# Disable autocorrect
unsetopt correct_all

# Use Alt-Arrows to skip words
#bindkey -e
#bindkey '^[[1;9C' forward-word
#bindkey '^[[1;9D' backward-word

HISTFILE=~/.history
HISTSIZE=10000
SAVEHIST=1000
HISTDUP=erase

# Append history to the history file (no overwriting)
setopt appendhistory

# Share history across terminals
setopt sharehistory

# Immediately append to the history file, not just when a term is killed
setopt incappendhistory

# Path
export PATH=$(eval echo -E $(cat ~/.dotfiles/path | tr "\n" ":")):$PATH

. ~/.dotfiles/exports.sh
. ~/.dotfiles/aliases.sh

fpath+=/opt/homebrew/share/zsh/site-functions
autoload -U promptinit; promptinit
prompt pure

# if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi
# if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi

. /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
. /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

eval "$(/opt/homebrew/bin/brew shellenv)"

# Plugins installation:
# cd /usr/local/share
# git clone https://github.com/zsh-users/zsh-autosuggestions.git
# git clone https://github.com/zsh-users/zsh-syntax-highlighting.git

. /opt/homebrew/opt/asdf/libexec/asdf.sh

# test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# # The next line updates PATH for Yandex Cloud CLI.
# if [ -f '/Users/alex/yandex-cloud/path.bash.inc' ]; then source '/Users/alex/yandex-cloud/path.bash.inc'; fi

# # The next line enables shell command completion for yc.
# if [ -f '/Users/alex/yandex-cloud/completion.zsh.inc' ]; then source '/Users/alex/yandex-cloud/completion.zsh.inc'; fi

# # Fig post block. Keep at the bottom of this file.
# . "$HOME/.fig/shell/zshrc.post.zsh"

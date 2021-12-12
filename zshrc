# Disable autocorrect
unsetopt correct_all

# Use Alt-Arrows to skip words
bindkey -e
bindkey '^[[1;9C' forward-word
bindkey '^[[1;9D' backward-word

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

source ~/.dotfiles/exports.sh
source ~/.dotfiles/aliases.sh

autoload -U promptinit; promptinit
prompt pure

if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi
# if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi

source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Plugins installation:
# cd /usr/local/share
# git clone git clone https://github.com/zsh-users/zsh-autosuggestions.git
# git clone https://github.com/zsh-users/zsh-syntax-highlighting.git

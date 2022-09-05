# Disable autocorrect
unsetopt correct_all

# Home
bindkey '^[[H' beginning-of-line
# End
bindkey '^[[F' end-of-line

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

#
# Path
#

export PATH=$(eval echo -E $(cat ~/.dotfiles/path | tr "\n" ":")):$PATH

#
# Homebrew
#

eval "$(/opt/homebrew/bin/brew shellenv)"

#
#  Zsh plugins
#

# Plugins installation:
# cd /usr/local/share
# git clone https://github.com/zsh-users/zsh-autosuggestions.git
# git clone https://github.com/zsh-users/zsh-syntax-highlighting.git

. /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
. /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

#
# Starship
#

eval "$(starship init zsh)"

#
# asdf
#

. /opt/homebrew/opt/asdf/libexec/asdf.sh

#
# Yandex Cloud CLI
#

# The next line updates PATH for Yandex Cloud CLI.
if [ -f '/Users/alex/yandex-cloud/path.bash.inc' ]; then source '/Users/alex/yandex-cloud/path.bash.inc'; fi

# The next line enables shell command completion for yc.
# if [ -f '/Users/alex/yandex-cloud/completion.zsh.inc' ]; then source '/Users/alex/yandex-cloud/completion.zsh.inc'; fi

#
# Env vars and aliases
#

. ~/.profile
. ~/.dotfiles/exports.sh
. ~/.dotfiles/aliases.sh

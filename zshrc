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

# Share history across terminals
setopt share_history

# Immediately append to the history file, not just when a term is killed
setopt inc_append_history

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
# git clone git@github.com:agkozak/zsh-z.git

. /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
. /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# . /usr/local/share/zsh-z/zsh-z.plugin.zsh

#
# Starship
#

eval "$(starship init zsh)"

#
# Base16 color scheme (Works with iTerm2)
#

. $HOME/.config/base16-shell/scripts/base16-3024.sh

#
# asdf
#

. /opt/homebrew/opt/asdf/libexec/asdf.sh

#
# Yandex Cloud CLI
#

# The next line updates PATH for Yandex Cloud CLI.
# if [ -f '/Users/alex/yandex-cloud/path.bash.inc' ]; then source '/Users/alex/yandex-cloud/path.bash.inc'; fi

# The next line enables shell command completion for yc.
# if [ -f '/Users/alex/yandex-cloud/completion.zsh.inc' ]; then source '/Users/alex/yandex-cloud/completion.zsh.inc'; fi

#
# Env vars and aliases
#

. ~/.profile
. ~/.dotfiles/exports.sh
. ~/.dotfiles/aliases.sh

# eval "$(rbenv init - zsh)"

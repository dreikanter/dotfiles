#
# Path
#

export PATH=$(eval echo -E $(cat ~/.dotfiles/path | tr "\n" ":")):$PATH

#
# Keybinding
#

# Home
bindkey '^[[H' beginning-of-line

# End
bindkey '^[[F' end-of-line

source "/opt/homebrew/opt/fzf/shell/key-bindings.zsh"

#
# History
#

export HISTFILE=~/.history
export HISTSIZE=10000
export SAVEHIST=1000
export HISTDUP=erase
export HISTCONTROL='ignoreboth';

# Share history across terminals
setopt share_history

# Immediately append to the history file, not just when a term is killed
setopt inc_append_history

#
# Homebrew
#

eval "$(/opt/homebrew/bin/brew shellenv)"

#
#  Zsh plugins
#

# Plugins installation:
# brew install zsh-autosuggestions zsh-syntax-highlighting
#
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

#
# Starship, https://starship.rs (brew install starship)
#

eval "$(starship init zsh)"

#
# asdf
#

# asdf plugin add ruby
# asdf list all ruby
# asdf plugin-update ruby
# asdf install ruby latest
# asdf global ruby 3.3.6

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

#
# fzf autocompletion with ctrl+r (installed with `$(brew --prefix)/opt/fzf/install`)
#

# Setup fzf
if [[ ! "$PATH" == */opt/homebrew/opt/fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/opt/homebrew/opt/fzf/bin"
fi

# Auto-completion
[[ $- == *i* ]] && source "/opt/homebrew/opt/fzf/shell/completion.zsh" 2> /dev/null

eval "$(atuin init zsh)"

#
# Misc
#

# Disable autocorrect
unsetopt correct_all

#
# Path
#

path=(
  $HOME/bin
  /usr/bin
  /bin
  /usr/sbin
  /sbin
)

export PATH

#
# Env vars
#

export LC_CTYPE=en_US.UTF-8
export LANG=en_US.UTF-8
export LANG11=en_US.UTF-8
export EDITOR="subl --wait"
export GOPATH=$HOME/go
export HOMEBREW_NO_AUTO_UPDATE=true
export JAVA_HOME=$(/usr/libexec/java_home)
export ES_JAVA_HOME=$JAVA_HOME
export NOTES_PATH=~/Dropbox/Notes
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git --exclude node_modules'
export FZF_DEFAULT_OPTS="--reverse --multi"

#
# Homebrew
#

eval "$(/opt/homebrew/bin/brew shellenv)"

#
# Mise
#

eval "$(mise activate zsh)"

#
# Aliases
#

# Core tools
alias branchtests="git diff --name-only --diff-filter=ACMRTUXB main...HEAD | grep _test.rb"
alias c="clear"
alias h="history -30 | cut -c 8-"
alias k="kubectl"
alias l1="eza --all --group-directories-first -1"
alias l="eza --all --long --group-directories-first"
alias prt="yarn run prettier --no-color --write"
alias r="PAGER=cat rails"
alias rc="PAGER=cat rails console"
alias railstb='rails test $(git diff --name-only --diff-filter=ACMRTUXB main...HEAD | grep _test.rb)'
alias s="subl ."
alias ss="subl --add ."
alias vim="nvim"

# Git

alias g="git status -s"

# Show recent commits log
alias gl="git log --pretty=format:\"%C(yellow)%h%Creset [%ad] %Cgreen%s%Creset %Cred%d%Creset %Cblue[%an]\" --date=short -n 20"

# List recent branches
alias gbr="git branch --sort=committerdate --color --format=\"%(color:red)%(objectname:short)%(color:reset) %(HEAD) %(color:yellow)%(refname:short)%(color:reset) (%(color:green)%(committerdate:relative)%(color:reset))\" | tail -n 10"

alias gto="git checkout"
alias gta="git add"
alias gtc="git commit -m"
alias gtm="git commit -m"
alias gp="git push -u origin HEAD"
alias gp!="git push -u --force origin HEAD"

# List file names modified in the current branch
alias gdf="git diff --name-only main...HEAD"

alias gdd="GIT_EXTERNAL_DIFF=difft git diff"
alias gd="git diff"
alias gdcp="git diff | pbcopy"

# Other

# Requires npm install pg-formatter -g
alias sqlf="pbpaste > /tmp/pg-formatter-sql.sql && pg-formatter /tmp/pg-formatter-sql.sql && rm /tmp/pg-formatter-sql.sql"

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

setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt inc_append_history
setopt share_history

#
# Starship, https://starship.rs (brew install starship)
#

eval "$(starship init zsh)"

#
# Env vars and aliases
#

. ~/.profile
. ~/.dotfiles/aliases.sh

#
# Auto-completion
#

[[ $- == *i* ]] && source "/opt/homebrew/opt/fzf/shell/completion.zsh" 2> /dev/null

#
# atuin
#

eval "$(atuin init zsh)"

#
# Zsh
#

unsetopt correct_all

# Plugins installation:
# brew install zsh-autosuggestions zsh-syntax-highlighting
#
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

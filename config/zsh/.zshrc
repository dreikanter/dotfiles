#
# Path
#

if [[ -x "/opt/homebrew/bin/brew" ]]; then
  # Homebrew installed
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

path=(
  $HOME/.local/bin
  $HOME/.opencode/bin
  $HOME/bin
  $path
)

typeset -U path
export PATH

#
# Env vars
#

export LC_CTYPE=en_US.UTF-8
export LANG=en_US.UTF-8
export VISUAL="subl --wait"
export EDITOR=nvim
export GOPATH=$HOME/go
export HOMEBREW_NO_AUTO_UPDATE=true

if [[ -x "/usr/libexec/java_home" ]]; then
  export JAVA_HOME=$(/usr/libexec/java_home 2>/dev/null)
  export ES_JAVA_HOME=$JAVA_HOME
fi

export NOTES_PATH=~/Dropbox/Notes
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git --exclude node_modules'
export FZF_DEFAULT_OPTS="--reverse --multi"

source ~/.profile

#
# Aliases
#

# Core tools
alias branchtests="git diff --name-only --diff-filter=ACMRTUXB main...HEAD | grep _test.rb"
alias c="clear"
alias h="history -30 | cut -c 8-"
alias k="kubectl"
alias l="eza --all --long --group-directories-first"
alias prt="yarn run prettier --no-color --write"
alias r="PAGER=cat rails"
alias railstb='rails test $(git diff --name-only --diff-filter=ACMRTUXB main...HEAD | grep _test.rb)'
alias rc="PAGER=cat rails console"
alias reload="source ~/.zshrc"
alias s="subl ."
alias ss="subl --add ."
alias v="nvim"
alias vconf="nvim ~/.config/nvim/init.lua"
alias vzsh="nvim ~/.zshrc"
alias vim="nvim"
alias t="eza --color=always --git-ignore -T -L 2"

# Git

alias g="git status -s"

# Show recent commits log
alias gl="git log --pretty=format:\"%C(yellow)%h%Creset [%ad] %Cgreen%s%Creset %Cred%d%Creset %Cblue[%an]\" --date=short -n 20"

# List recent branches
alias gbr="git branch --sort=committerdate --color --format=\"%(color:red)%(objectname:short)%(color:reset) %(HEAD) %(color:yellow)%(refname:short)%(color:reset) (%(color:green)%(committerdate:relative)%(color:reset))\" | tail -n 10"

alias gp="git push -u origin HEAD"
alias gpforce="git push -u --force-with-lease origin HEAD"

# List file names modified in the current branch
alias gdf="git diff --name-only main...HEAD"

alias gdd="GIT_EXTERNAL_DIFF=difft git diff"
alias gd="git diff"
alias gdcp="git diff | pbcopy"

# Other

# Requires npm install pg-formatter -g
alias sqlf="pbpaste > /tmp/pg-formatter-sql.sql && pg-formatter /tmp/pg-formatter-sql.sql && rm /tmp/pg-formatter-sql.sql"

# Yazi
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

#
# Keybinding
#

# Home
bindkey '^[[H' beginning-of-line

# End
bindkey '^[[F' end-of-line

[[ -r "/opt/homebrew/opt/fzf/shell/key-bindings.zsh" ]] && source "/opt/homebrew/opt/fzf/shell/key-bindings.zsh"

bindkey -v
bindkey '^[' vi-cmd-mode

#
# History
#

export HISTFILE=~/.history
export HISTSIZE=10000
export SAVEHIST=10000
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

command -v atuin >/dev/null && eval "$(atuin init zsh)"

command -v mise >/dev/null && eval "$(mise activate zsh)"

#
# Fzf completion (vim **<TAB>; cd /usr/**<TAB>)
#

[[ -r "/opt/homebrew/opt/fzf/shell/completion.zsh" ]] && [[ $- == *i* ]] &&
  source "/opt/homebrew/opt/fzf/shell/completion.zsh"

# Plugins installation:
# brew install zsh-autosuggestions zsh-syntax-highlighting
#
[[ -r "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] &&
  source "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
[[ -r "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] &&
  source "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

unsetopt correct_all

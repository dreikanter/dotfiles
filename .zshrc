ZSH=$HOME/.oh-my-zsh

plugins=(git)

# Themes directory: $HOME/.oh-my-zsh
export ZSH_THEME="robbyrussell"
DISABLE_AUTO_UPDATE="true"
source $ZSH/oh-my-zsh.sh

# Disable autocorrect
unsetopt correct_all

# set -x

# Prompt
function get_pwd() {
  echo "${PWD/$HOME/~}"
}

function git_info() {
   ref=$(git symbolic-ref HEAD 2> /dev/null) || return
   echo " git:$(current_branch)"
}

function rbenv_ver() {
  if which rbenv &> /dev/null; then
    local ver=$(rbenv version-name)
    [ "$(rbenv global)" != "$ver" ] && echo " ruby:$ver"
  fi
}

PROMPT='
%{$fg[cyan]%}%n@%{$fg[cyan]%}%m: %B%{$fg[yellow]%}$(get_pwd)%b%{$fg[green]%}$(git_info)%{$fg[red]%}$(rbenv_ver)
%{$reset_color%}> '

# Use Alt-Arrows to skip words
bindkey -e
bindkey '^[[1;9C' forward-word
bindkey '^[[1;9D' backward-word

export GOPATH=$HOME/go

# Path
export PATH=$(eval echo -E $(cat ~/.path | tr "\n" ":")):$PATH

# Env vars
source ~/.exports

# Environment managers
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi
if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi

# Aliases
source ~/.aliases

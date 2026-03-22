#
# Path
#

if [[ -x "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

path=(
  /opt/homebrew/opt/llvm/bin
  $HOME/.local/bin
  $HOME/.opencode/bin
  $HOME/bin
  $HOME/go/bin
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

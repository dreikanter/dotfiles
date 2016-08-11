# Path to Oh My Fish install.
set -q XDG_DATA_HOME
  and set -gx OMF_PATH "$XDG_DATA_HOME/omf"
  or set -gx OMF_PATH "$HOME/.local/share/omf"

# Load Oh My Fish configuration.
source $OMF_PATH/init.fish
# Set CLICOLOR if you want Ansi Colors in iTerm2
set -x CLICOLOR 1

# Path to Oh My Fish install.
# set -gx OMF_PATH /Users/dreikanter/.local/share/omf

# Load oh-my-fish configuration.
# source $OMF_PATH/init.fish

set fish_plugins rbenv rake bundler
set -gx GOPATH $HOME/Projects/gocode
set -gx PATH $GOPATH/bin $PATH

set -gx PYENV_ROOT $HOME/.pyenv
set -gx PATH $PYENV_ROOT/bin $PYENV_ROOT/shims $PATH

set -gx RBENV_ROOT $HOME/.rbenv
set -gx PATH $RBENV_ROOT/bin $RBENV_ROOT/plugins/ruby-build/bin $PATH

eval (docker-machine env default)

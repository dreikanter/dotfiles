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
# prompt_newline='%666v'
# PROMPT="$PROMPT"

if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi
# if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi

source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Plugins installation:
# cd /usr/local/share
# git clone git clone https://github.com/zsh-users/zsh-autosuggestions.git
# git clone https://github.com/zsh-users/zsh-syntax-highlighting.git

# # fuzzy grep open via rg with line number
# pp() {
#   local file
#   local line

#   read -r file line <<<"$(rg -l ${@:-''} | fzf -0 -1 --preview-window='50%' --preview='bat {} --color=always' | awk -F: '{print $1, $2}')"

#   if [[ -n $file ]]
#   then
#      subl $file:$line
#   fi
# }

# # Ctrl-F (Find in Files)
# RG_PREFIX='rg --column --line-number --no-heading --color=always --smart-case '
# # RG_PREFIX='rg --line-number --color=always --smart-case '
# INITIAL_QUERY=''
# FZF_DEFAULT_COMMAND="$RG_PREFIX '$INITIAL_QUERY' ."

# __fif() {
#     fzf --bind "change:reload:$RG_PREFIX {q} . || true" --ansi --phony --query "$INITIAL_QUERY" --preview-window='50%' --preview='bat {} --color=always' | cut -d ':' -f1
# }

# find-in-files() {
#   LBUFFER="${LBUFFER}$(__fif)"
#   local ret=$?
#   zle reset-prompt
#   return $ret
# }

# zle -N find-in-files
# bindkey '^f' find-in-files

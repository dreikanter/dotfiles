#
# Core tools
#

# alias l="exa --all --long --group-directories-first"
alias l="eza --all --long --group-directories-first"
alias h="history -30 | cut -c 8-"
alias k="kubectl"
alias vim="nvim"
alias branchtests="git diff --name-only --diff-filter=ACMRTUXB main...HEAD | grep _test.rb"
alias railstb='rails test $(git diff --name-only --diff-filter=ACMRTUXB main...HEAD | grep _test.rb)'
alias s="subl ."
alias ss="subl --add ."
alias prt="yarn run prettier --no-color --write"
alias r=rails

#
# Git
#

alias g="git status -s"

# Show recent commits log
alias gl="git log --pretty=format:\"%C(yellow)%h%Creset [%ad] %Cgreen%s%Creset %Cred%d%Creset %Cblue[%an]\" --date=short -n 20"

# List recent branches
alias gbr="git branch --sort=committerdate --color --format=\"%(color:red)%(objectname:short)%(color:reset) %(HEAD) %(color:yellow)%(refname:short)%(color:reset) (%(color:green)%(committerdate:relative)%(color:reset))\" | tail -n 10"

alias gph="git push -u origin HEAD"

alias gdf="git diff --name-only main...HEAD"
alias gdd="GIT_EXTERNAL_DIFF=difft git diff"
alias gd="git diff"
alias gdc="git diff | pbcopy"

#
# Other
#

alias rc="PAGER=cat rails console"

# Requires npm install pg-formatter -g
alias sqlf="pbpaste > /tmp/pg-formatter-sql.sql && pg-formatter /tmp/pg-formatter-sql.sql && rm /tmp/pg-formatter-sql.sql"

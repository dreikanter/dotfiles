#
# Core tools
#

alias l="exa --all --long --group-directories-first"
alias h="history | cut -c 8-"
alias k="kubectl"
alias vim="nvim"
alias railstb="rails test $(git diff HEAD main --name-only | grep _test)"
alias s="subl ."
alias ss="subl --add ."

#
# Git
#

alias g="git status -s"
alias gl="git log --pretty=format:\"%C(yellow)%h%Creset %ad | %Cgreen%s%Creset %Cred%d%Creset %Cblue[%an]\" --date=short -n 20"
alias gbl="git log --no-merges HEAD ^master --reverse --pretty=\"format:* %s\" --abbrev-commit"
alias gbr="git branch --sort=committerdate --color --format=\"%(color:red)%(objectname:short)%(color:reset) %(HEAD) %(color:yellow)%(refname:short)%(color:reset) (%(color:green)%(committerdate:relative)%(color:reset))\" | tail -n 10"

function gb() {
  git checkout "$(git branch --sort=committerdate | tac | fzf | tr -d '[:space:]')"
}

killport() { kill -9 $(lsof -t -i:$1) }

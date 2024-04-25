#
# Core tools
#

# alias l="exa --all --long --group-directories-first"
alias l="eza --all --long --group-directories-first"
alias h="history -30 | cut -c 8-"
alias k="kubectl"
alias vim="nvim"
alias railstb="rails test $(git diff HEAD main --name-only | grep _test.rb)"
alias s="subl ."
alias ss="subl --add ."

#
# Git
#

alias g="git status -s"
alias gl="git log --pretty=format:\"%C(yellow)%h%Creset %ad | %Cgreen%s%Creset %Cred%d%Creset %Cblue[%an]\" --date=short -n 20"
alias gbl="git log --no-merges HEAD ^master --reverse --pretty=\"format:* %s\" --abbrev-commit"
alias gbr="git branch --sort=committerdate --color --format=\"%(color:red)%(objectname:short)%(color:reset) %(HEAD) %(color:yellow)%(refname:short)%(color:reset) (%(color:green)%(committerdate:relative)%(color:reset))\" | tail -n 10"
alias gph="git push -u origin HEAD"
alias gdf="git diff --name-only main...HEAD"
alias gdd="GIT_EXTERNAL_DIFF=difft git diff"

gcm() { git commit -m $1 }

function gb() {
  git checkout "$(git branch --sort=committerdate | tac | fzf --height 20 | tr -d '[:space:]')"
}

gp() {
  local current_branch=$(git rev-parse --abbrev-ref HEAD)

  if [ -z "$current_branch" ]; then
    echo "Could not determine the current branch."
    return 1
  fi

  if [ "$current_branch" = "HEAD" ]; then
    echo "You are in 'detached HEAD' state. You need to checkout a branch before you can push."
    return 1
  fi

  git push -u origin "$current_branch"
}

gpf() {
  local current_branch=$(git rev-parse --abbrev-ref HEAD)

  if [ -z "$current_branch" ]; then
    echo "Could not determine the current branch."
    return 1
  fi

  if [ "$current_branch" = "HEAD" ]; then
    echo "You are in 'detached HEAD' state. You need to checkout a branch before you can push."
    return 1
  fi

  git push -u --force origin "$current_branch"
}

#
# Other
#

killport() { kill -9 $(lsof -t -i:$1) }

alias rc="PAGER=cat rails console"

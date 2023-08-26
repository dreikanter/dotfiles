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

alias g="git status"
# alias gl="git log --graph --decorate --pretty=oneline --abbrev-commit -n 15"
alias gl="git log --pretty=format:\"%C(yellow)%h%Creset %ad | %Cgreen%s%Creset %Cred%d%Creset %Cblue[%an]\" --date=short -n 20"
alias gbl="git log --no-merges HEAD ^master --reverse --pretty=\"format:* %s\" --abbrev-commit"
alias gbr="git branch --sort=committerdate --color --format=\"%(color:red)%(objectname:short)%(color:reset) %(HEAD) %(color:yellow)%(refname:short)%(color:reset) (%(color:green)%(committerdate:relative)%(color:reset))\" | tail -n 10"

function gb() {
  git checkout "$(git branch --sort=committerdate | tac | fzf | tr -d '[:space:]')"
}

# "Git branch create"
function gbc() {
  git stash
  git checkout master
  git pull --rebase upstream master
  git checkout -b $1
  git stash pop
}

#
# Amplifr
#

amplifr_name() {
  kubectl --kubeconfig ~/.kube/config get pod -n $1|grep Running|grep web|tail -1|awk '{print $1}'
}

amplifr_exec() {
  kubectl --kubeconfig ~/.kube/config exec -it -n $1 $(amplifr_name $1) -- $(echo $2)
}

amplifr_logs() {
  kubectl --kubeconfig ~/.kube/config logs -f -n $1 --context yandex $(amplifr_name $1)
}

# Production
alias aprailsc="amplifr_exec 'amplifr-app' 'bundle exec rails c'"
alias apbash="amplifr_exec 'amplifr-app' 'bundle exec /bin/bash'"
alias aplogs="amplifr_logs 'amplifr-app'"

# Staging
alias asrailsc="amplifr_exec 'amplifr-staging' 'bundle exec rails c'"
alias asbash="amplifr_exec 'amplifr-staging' 'bundle exec /bin/bash'"
alias aslogs="amplifr_logs 'amplifr-staging'"

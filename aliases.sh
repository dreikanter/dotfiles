# Core tools
alias l="exa --all --long --group-directories-first"
alias h="history"
alias e="subl"
alias p="ps aux"
alias rr="clear && rg --color=always --ignore-case --context 1  --max-columns 100 --max-columns-preview"
alias k=kubectl
alias d=docker-compose

# Git
alias g="git status"
alias gl="git log --graph --decorate --pretty=oneline --abbrev-commit -n 15"
alias gb="git branch --sort=committerdate --color --format=\"%(color:red)%(objectname:short)%(color:reset) %(HEAD) %(color:yellow)%(refname:short)%(color:reset) (%(color:green)%(committerdate:relative)%(color:reset))\" | tail -n 10"

# Amplifr
alias dcrun="docker-compose run runner bundle exec"
alias dcup="docker-compose up"

# NOTE: Moved to fish functions

amplifr_name() {
  kubectl --kubeconfig ~/.kube/config get pod -n $1|grep Running|grep web|tail -1|awk '{print $1}'
}

amplifr_exec() {
  kubectl --kubeconfig ~/.kube/config exec -it -n $1 $(amplifr_name $1) -- $(echo $2)
}

amplifr_logs() {
  kubectl --kubeconfig ~/.kube/config logs -f -n $1 --context amplifr $(amplifr_name $1)
}

# Production
alias aprailsc="amplifr_exec 'amplifr-app' 'bundle exec rails c'"
alias apbash="amplifr_exec 'amplifr-app' 'bundle exec /bin/bash'"
alias aplogs="amplifr_logs 'amplifr-app'"

# Staging
alias asrailsc="amplifr_exec 'amplifr-staging' 'bundle exec rails c'"
alias asbash="amplifr_exec 'amplifr-staging' 'bundle exec /bin/bash'"
alias aslogs="amplifr_logs 'amplifr-staging'"

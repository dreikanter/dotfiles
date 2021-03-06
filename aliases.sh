# Core tools
alias l="exa --all --long --group-directories-first"
alias h="history"
alias e="subl"
alias p="ps aux"
alias rr="clear && rg --color=always --ignore-case --context 1  --max-columns 100 --max-columns-preview"

# Git
alias g="git status"
alias gl="git log --graph --decorate --pretty=oneline --abbrev-commit -n 15"
alias gb="git branch --sort=committerdate --format='%(color:red)%(objectname:short)%(color:reset) %(HEAD) %(color:yellow)%(refname:short)%(color:reset) (%(color:green)%(committerdate:relative)%(color:reset))'"

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

# alias amplifr_prod_railsc="amplifr_exec 'amplifr-app' 'bundle exec rails c'"
# alias amplifr_prod_bash="amplifr_exec 'amplifr-app' 'bundle exec /bin/bash'"
# alias amplifr_prod_rr="amplifr_exec 'amplifr-app' 'bundle exec rails r -'"

# alias amplifr_stag_railsc="amplifr_exec 'amplifr-staging' 'bundle exec rails c'"
# alias amplifr_stag_bash="amplifr_exec 'amplifr-staging' 'bundle exec bash'"
# alias amplifr_stag_rr="amplifr_exec 'amplifr-staging' 'bundle exec rails r -'"

# Production
alias aprailsc="amplifr_exec 'amplifr-app' 'bundle exec rails c'"
alias apbash="amplifr_exec 'amplifr-app' 'bundle exec /bin/bash'"
alias aplogs="amplifr_logs 'amplifr-app'"

# Staging
alias asrailsc="amplifr_exec 'amplifr-staging' 'bundle exec rails c'"
alias asbash="amplifr_exec 'amplifr-staging' 'bundle exec /bin/bash'"
alias aslogs="amplifr_logs 'amplifr-staging'"

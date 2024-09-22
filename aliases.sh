#
# Core tools
#

# alias l="exa --all --long --group-directories-first"
alias l="eza --all --long --group-directories-first"
alias h="history -30 | cut -c 8-"
alias k="kubectl"
alias vim="nvim"
alias railstb='rails test $(git diff --name-only --diff-filter=ACMRTUXB main...HEAD | grep _test.rb)'
alias s="subl ."
alias ss="subl --add ."
alias prt="yarn run prettier --no-color --write"

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

gcm() { git commit -m $1 }

# Switch branch interactively
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

# Requires npm install pg-formatter -g
alias sqlf="pbpaste > /tmp/pg-formatter-sql.sql && pg-formatter /tmp/pg-formatter-sql.sql && rm /tmp/pg-formatter-sql.sql"

# Usage: railsi banana.banana
# The default locale is "en"
railsi() {
  ruby -rjson -ryaml -e "
    file = 'config/locales/en.yml'
    path = 'en.' + ARGV[0]
    data = YAML.load_file(file)
    result = path ? data.dig(*path.split('.')) : data
    puts JSON.pretty_generate(result)
  " "$1"
}

# Show diff Rails project routing between the `main` and the current branch HEAD revisions
railsroutesdiff() {
  current_branch=$(git rev-parse --abbrev-ref HEAD)

  git checkout main &&
    rails routes > before.txt &&
    git checkout "$current_branch" &&
    rails routes > after.txt &&
    diff -u -b before.txt after.txt | diff-so-fancy
}

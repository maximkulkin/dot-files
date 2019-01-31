source ~/.dot-files/git-prompt.sh
source ~/.dot-files/git-completion.bash

export PATH="~/.dot-files/bin:$PATH"

export GIT_PS1_SHOWDIRTYSTATE=1
export PS1='\[\033[01;34m\]\w\[\033[32m\]$(__git_ps1)\[\033[1;33m\] >\[\033[00m\] '
if [ "$USER" == "vagrant" ]; then
  export PS1="\[\033[01;31m\][vagrant]\[\033[00m\] $PS1"
fi

export EDITOR=vim
alias e="vim"

alias ls="ls -GF"

# Git aliases
alias ga="git add"
alias gap="git add -p"
alias gs="git status"
alias gb="git branch"
alias gbr='git for-each-ref --sort="-authordate:iso8601" --format="%(color:green)%(authordate:iso8601)%09%(color:white)%(refname:short)" refs/heads'
alias gd="git diff"
alias gdc="git diff --cached"
alias gc="git commit"
alias gca="git commit --amend"
alias gcf="git commit --fixup"
alias go="git checkout"
alias gom="git checkout master"
alias gfo="git fetch origin"
alias gu="git pull --rebase"
alias gp!="git push origin"
alias gl="git log"
alias glm="git log master.."
alias glmo="git log master.. --oneline"
alias glo="git log --oneline"
alias grm="git rebase master"
alias gcont="git rebase --continue"
alias gabort="git rebase --abort"
alias gss="git stash save"
alias gsp="git stash pop"
alias gsl="git stash list"
alias gsh="git stash show -u"

__git_complete ga _git_add
__git_complete gap _git_add
__git_complete gb _git_branch
__git_complete go _git_checkout
__git_complete gl _git_log
__git_complete glm _git_log
__git_complete glmo _git_log
__git_complete glo _git_log
__git_complete gu _git_pull
__git_complete gd _git_diff
__git_complete gdc _git_diff
__git_complete gc _git_commit
__git_complete gca _git_commit
__git_complete gcf _git_commit

gri() {
  local base=${1:-master}
  git rebase -i $(git merge-base $base HEAD)
}

alias json="python -mjson.tool"

if [[ $(uname) == "Darwin" ]]; then
  docker() {
    if [[ -z "$DOCKER_HOST" ]]; then
      echo "DOCKER_HOST is not set, initializing docker machine 'default'"
      eval $(docker-machine env default)
    fi

    command docker "$@"
  }
fi

alias v=vagrant

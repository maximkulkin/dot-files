source ~/.dot-files/git-prompt.sh
source ~/.dot-files/git-completion.bash

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
alias gs="git status"
alias gb="git branch"
alias gd="git diff"
alias gdc="git diff --cached"
alias gc="git commit"
alias go="git checkout"
alias gom="git checkout master"
alias gfo="git fetch origin"
alias gu="git pull --rebase"
alias gp!="git push origin"
alias gl="git log"
alias glm="git log master.."
alias grm="git rebase master"
alias gcont="git rebase --continue"
alias gabort="git rebase --abort"

gri() {
  local base=${1:-master}
  git rebase -i $(git merge-base $base HEAD)
}

alias json="python -mjson.tool"

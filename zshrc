setopt prompt_subst
source ~/.dot-files/git-prompt.sh

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname \"$ZINIT_HOME\")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "$ZINIT_HOME/zinit.zsh"

# Add prompt plugin
zinit ice depth=1; zinit light romkatv/powerlevel10k
# Add completion plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions

# Load completions
autoload -U compinit && compinit

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_dups
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_find_no_dups

bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

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
alias gsmu="git submodule update --init --recursive"

gri() {
  local base=${1:-master}
  git rebase -i $(git merge-base $base HEAD)
}

alias ls="ls -FG"

# zmodload -i zsh/complist
# zstyle ':completion:*' list-colors ''   # use colors in completion
# zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
# zstyle ':completion:*' list-suffixes
# zstyle ':completion:*' menu no
# setopt no_auto_menu

export EDITOR=nvim
alias vim=nvim
alias e=nvim

docker-run() {
  docker run -it --rm -v $(pwd):/project -w /project "$@"
}

xdocker-run() {
  x-docker run -it --rm -v $(pwd):/project -w /project "$@"
}

function idfpy_bootstrap {
  unalias idf.py
  if ! which idf.py ; then
    source ~/Projects/esp/esp-idf/export.sh
  fi
  idf.py "$@"
}
alias idf.py=idfpy_bootstrap
alias idf=idf.py
alias idf-b="idf build"
alias idf-fm="idf flash monitor"

source <(fzf --zsh)
zinit light ~/.dot-files/third-party/fzf-tab

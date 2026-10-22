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
# To accept autosuggest press Ctrl+f

zinit ice as"program" pick"bin/git-fuzzy"
zinit light bigH/git-fuzzy

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

# Preview scrolling for every fzf: Ctrl-D/Ctrl-U page, Ctrl-J/Ctrl-K line
export FZF_DEFAULT_OPTS="--bind='ctrl-d:preview-page-down,ctrl-u:preview-page-up,ctrl-j:preview-down,ctrl-k:preview-up'"
# fzf-tab ignores FZF_DEFAULT_OPTS unless told otherwise
zstyle ':fzf-tab:*' use-fzf-default-opts yes

zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':completion:*' list-suffixes true
zstyle ':completion:*' expand prefix suffix
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

alias gs="git status --short"
alias gb="git branch"
alias gbr='git for-each-ref --sort="-authordate:iso8601" --format="%(color:green)%(authordate:iso8601)%09%(color:white)%(refname:short)" refs/heads'
alias gc="git commit"
alias gca="git commit --amend"
alias go="git checkout"
alias gom="git checkout master"
alias gfo="git fetch origin"
alias gu="git pull --rebase"
alias gp!="git push origin"
alias gl="git log"
alias glo="git log --oneline"
alias gcont="git rebase --continue"
alias gabort="git rebase --abort"
alias gss="git stash save"
alias gsl="git stash list"
alias gsmu="git submodule update --init --recursive"
alias ge='e $(git diff --name-only --diff-filter=U)'

# gd / gdc / ga / gap / gsh / gsp / gsd / gcf are functions rather than aliases
# so they can have their own completion: Tab offers only the relevant files
# (or stashes, commits), shown in fzf (via fzf-tab) with a preview. `function
# name {` form so re-sourcing doesn't clash with the old aliases.
unalias gd gdc ga gap gsh gsp gsd gcf 2>/dev/null
function gd  { git diff "$@" }
function gdc { git diff --cached "$@" }
function ga  { git add "$@" }
function gap { git add --patch "$@" }
function gsh { git stash show -u "$@" }
function gsp { git stash pop "$@" }
function gsd { git stash drop "$@" }
function gcf { git commit --fixup "$@" }

# Complete options as for the wrapped git command, e.g. `git diff --cached -...`
_git_wrapper_complete_options() {
  words=("$@" "${(@)words[2,-1]}")
  (( CURRENT += $# - 1 ))
  _normal
}

# Complete the paths printed (NUL-separated, repo-root relative) by command
# "$@", made relative to $PWD and minus those already on the command line.
_git_wrapper_complete_paths() {
  local descr=$1; shift
  local prefix cdup f
  prefix=$(git rev-parse --show-prefix 2>/dev/null) || return 1
  cdup=$(git rev-parse --show-cdup)

  local -a paths files
  paths=(${(0)"$("$@")"})
  for f in $paths; do
    if [[ $f == $prefix* ]]; then
      files+=(${f#$prefix})
    else
      files+=($cdup$f)
    fi
  done

  local -a already=(${(Q)words[2,CURRENT-1]})
  files=(${files:|already})

  _wanted files expl $descr compadd -a files
}

_git_staged_paths()    { git diff --cached --name-only -z }
_git_modified_paths()  { git diff --name-only -z }
_git_untracked_paths() { git ls-files --others --exclude-standard --full-name -z -- :/ }
_git_addable_paths()   { _git_modified_paths; _git_untracked_paths }

_gd() {
  [[ $PREFIX == -* ]] && { _git_wrapper_complete_options git diff; return }
  _git_wrapper_complete_paths 'modified file' _git_modified_paths
}
_gdc() {
  [[ $PREFIX == -* ]] && { _git_wrapper_complete_options git diff --cached; return }
  _git_wrapper_complete_paths 'staged file' _git_staged_paths
}
_ga() {
  [[ $PREFIX == -* ]] && { _git_wrapper_complete_options git add; return }
  _git_wrapper_complete_paths 'modified or untracked file' _git_addable_paths
}
_gap() {
  [[ $PREFIX == -* ]] && { _git_wrapper_complete_options git add --patch; return }
  _git_wrapper_complete_paths 'modified file' _git_modified_paths
}
# Complete a single stash; options as for the wrapped command "$@"
_git_wrapper_complete_stash() {
  [[ $PREFIX == -* ]] && { _git_wrapper_complete_options "$@"; return }
  # Only one stash argument
  local w
  for w in $words[2,CURRENT-1]; do [[ $w == -* ]] || return 1; done

  # Complete the bare index N ("N:message", newest first): git accepts it for
  # stash@{N}, and it avoids zsh inserting the braces escaped as stash@\{N\}
  local -a stashes
  stashes=(${(f)"$(git stash list --format='%gd:%gs' 2>/dev/null)"})
  stashes=(${${stashes#stash@\{}/\}:/:})
  _describe -V -t stashes stash stashes
}

_gsh() { _git_wrapper_complete_stash git stash show -u }
_gsp() { _git_wrapper_complete_stash git stash pop }
_gsd() { _git_wrapper_complete_stash git stash drop }

# Complete one commit: those on the current branch since master/main, plus
# with --with-branch-point the commit the branch starts from; on master/main
# itself (or if neither exists), all commits
_git_wrapper_complete_branch_commit() {
  # Only one commit argument
  local w
  for w in $words[2,CURRENT-1]; do [[ $w == -* ]] || return 1; done

  local base range=HEAD fork
  base=$(_git_find_master_branch 2>/dev/null)
  if [[ -n $base && $(git symbolic-ref --short -q HEAD) != $base ]]; then
    range=$base..HEAD
    [[ $1 == --with-branch-point ]] && fork=$(git merge-base $base HEAD 2>/dev/null)
  fi

  local -a commits
  commits=(${(f)"$(git log --format='%h:%s' $range -- 2>/dev/null)"})
  [[ -n $fork ]] && commits+=("$(git log -1 --format='%h:[branch point] %s' $fork)")
  _describe -V -t commits commit commits
}

_gcf() {
  [[ $PREFIX == -* ]] && { _git_wrapper_complete_options git commit; return }
  _git_wrapper_complete_branch_commit
}
# gri passes only its first argument on, so there are no options to complete
_gri() { _git_wrapper_complete_branch_commit --with-branch-point }
compdef _gd gd
compdef _gdc gdc
compdef _ga ga
compdef _gap gap
compdef _gsh gsh
compdef _gsp gsp
compdef _gsd gsd
compdef _gcf gcf
compdef _gri gri

zstyle ':fzf-tab:complete:gdc:*' fzf-preview 'git diff --cached --color=always -- $word'
zstyle ':fzf-tab:complete:(gd|gap):*' fzf-preview 'git diff --color=always -- $word'
# Untracked files have no diff, so show them as all-new
zstyle ':fzf-tab:complete:ga:*' fzf-preview \
  'if git ls-files --error-unmatch -- $word >/dev/null 2>&1; then git diff --color=always -- $word; else git diff --no-index --color=always -- /dev/null $word; fi'
# Multi-select: Tab / Shift-Tab mark files (fzf-tab's default is Ctrl-Space)
zstyle ':fzf-tab:complete:(gd|gdc|ga|gap):*' fzf-bindings 'tab:toggle+down' 'btab:toggle+up'
# Bigger preview: full height (fzf-tab caps it at 2/3 of the terminal), wider pane
zstyle ':fzf-tab:complete:(gd|gdc|ga|gap):*' fzf-min-height 1000
zstyle ':fzf-tab:complete:(gd|gdc|ga|gap):*' fzf-flags '--preview-window=right:70%'

# Preview shows the changed files; Ctrl-T toggles to the full diff and back.
# The preview label holds the current mode, so the preview reads it.
zstyle ':fzf-tab:complete:(gsh|gsp|gsd):*' fzf-preview \
  'if [[ $FZF_PREVIEW_LABEL == " diff"* ]]; then git stash show -u -p --color=always $word; else git stash show -u --stat --color=always $word; fi'
zstyle ':fzf-tab:complete:(gcf|gri):*' fzf-preview \
  'if [[ $FZF_PREVIEW_LABEL == " diff"* ]]; then git show --color=always $word; else git show --stat --color=always $word; fi'
zstyle ':fzf-tab:complete:(gsh|gsp|gsd|gcf|gri):*' fzf-bindings \
  'ctrl-t:transform-preview-label([[ $FZF_PREVIEW_LABEL == " diff"* ]] && echo " changed files · ctrl-t: diff " || echo " diff · ctrl-t: changed files ")+refresh-preview'
# Stash/commit messages and --stat lines are both wide, so put the preview below
zstyle ':fzf-tab:complete:(gsh|gsp|gsd|gcf|gri):*' fzf-min-height 1000
zstyle ':fzf-tab:complete:(gsh|gsp|gsd|gcf|gri):*' fzf-flags '--preview-window=down:70%' \
  '--preview-label= changed files · ctrl-t: diff '

_git_find_master_branch() {
  for b in master main; do
    if [ -n "$(git branch --list $b)" ]; then
      echo $b
      return 0
    fi
  done
  if [ -z "$branch" ]; then
    echo "Failed to determine master branch" 1>&2
    return 1
  fi
}

glm() {
  git log "$(_git_find_master_branch).." "$@"
}

glmo() {
  git log "$(_git_find_master_branch).." --oneline "$@"
}

grm() {
  git rebase "$(_git_find_master_branch)" "$@"
}

gri() {
  local base=${1:-$(_git_find_master_branch)}
  git rebase -i $(git merge-base "$base" HEAD)
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
alias ec="( cd ~/.config/nvim && nvim )"
alias c=claude

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

# source <(fzf --zsh)
source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
zinit light Aloxaf/fzf-tab

export HOMEBREW_NO_ENV_HINTS=1
eval "$(/opt/homebrew/bin/brew shellenv)"

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"

hide-desktop() {
  # On macOS hides icons on desktop
  defaults write com.apple.finder CreateDesktop false
  killall Finder
}

show-desktop() {
  # On macOS shows (previously hidden) icons on desktop
  defaults write com.apple.finder CreateDesktop true
  killall Finder
}

# Disbale Claude Code mouse click/drag capture (keep scrolling)
# export CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1

# Create a widget to fuzzy-select and foreground a background job
fzf-jobs-widget() {
  if [[ -z "$(jobs)" ]]; then
    zle -M "No background jobs found."
    return
  fi

  local selected_job
  # List jobs, pass to fzf, and extract the job ID (e.g. %1)
  selected_job=$(jobs | fzf --ansi --no-sort --reverse --height ~40% | awk -F'[][]' '{print "%" $2}')

  if [[ -n "$selected_job" ]]; then
    # Insert 'fg %1' into the command line buffer and run it
    BUFFER="fg $selected_job"
    zle accept-line
  fi
}

# Register function as ZLE widget
zle -N fzf-jobs-widget

# Bind widget to Ctrl+J
bindkey '^J' fzf-jobs-widget

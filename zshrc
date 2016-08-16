[[ -z "${ORIGINAL_VARS}" ]] && ORIGINAL_VARS="$(declare -px)"
typeset +x ORIGINAL_VARS
[[ -n "${FIX_PATH}" ]] && PATH="$FIX_PATH" && unset FIX_PATH
[[ -n "${RUN_WITH}" ]] && eval "$RUN_WITH" && unset RUN_WITH

HISTFILE=~/.histfile
HISTSIZE=100000
SAVEHIST=100000

setopt EXTENDED_GLOB NO_NOMATCH NOTIFY
setopt HIST_IGNORE_SPACE HIST_IGNORE_DUPS
setopt COMPLETE_ALIASES
setopt PROMPT_SUBST  # variables in prompt
#setopt SH_WORD_SPLIT  # uncomment for compatibility with obscure bash scripts
REPORTTIME=1  # if a command takes longer than this many seconds of cpu time, show its time

bindkey -e

zstyle ':compinstall' filename "$HOME/.zshrc"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'  # case-insensitive tab completion
zstyle ':completion:*' insert-tab pending  # paste with tabs doesn't start completion
zstyle ':completion:*' menu select  # complete with arrow key selection
#zstyle ':completion:*:*:gradle:*' gradle-inspect no  # just use simple gradle completion
autoload -Uz compinit && compinit -i > /dev/null

[[ -d /usr/local/share/zsh-completions ]] && fpath=(/usr/local/share/zsh-completions $fpath)

which rbenv &>/dev/null && eval "$(rbenv init -)"

mkcd() {
    local dir="$*"
    mkdir -p "$dir" && cd "$dir"
}

cd() {
    [[ -z "$@" ]] && set_iterm_tab_rgb
    builtin cd "$@"
}

set_iterm_tab_rgb() {
    [[ "$TERM_PROGRAM" != "iTerm.app" ]] && return
    [[ -n "${NO_ITERM_TAB_COLOR+set}" ]] && return
    if [[ -z "$@" ]]; then
        echo -ne "\e]6;1;bg;*;default\a"  # reset
    else
        echo -ne "\e]6;1;bg;red;brightness;${1}\a\e]6;1;bg;green;brightness;${2}\a\e]6;1;bg;blue;brightness;${3}\a"
    fi
}

reset_env() {
    local command="$1"
    # assume login shell for now
    # OS X messes with the path in /etc/profile and /etc/zprofile. FIX_PATH works around this
    exec env -i ORIGINAL_VARS="$ORIGINAL_VARS" RUN_WITH="$command" "$(which zsh)" -d -c '
        eval "$ORIGINAL_VARS"
        FIX_PATH="$PATH" RUN_WITH="$RUN_WITH" $(which zsh) -l'
}

apply_aliases() {
    # ls
    if [[ "$OSTYPE" == "darwin"* ]]; then
        export CLICOLOR=1
        export LSCOLORS=gxBxhxDxfxhxhxhxhxcxcx
        alias ls="ls -Gp"
    fi
    [[ "$OSTYPE" == "linux-gnu" ]] && alias ls="ls --color=auto -p"
    alias l="ls"
    alias la="ls -a"
    alias ll="ls -la"
    alias lr="ls -R"
    alias lz="ls -rS"  # sort by size
    alias lt="ls -rT"  # sort by timestamp

    # modified commands
    which gtar &>/dev/null && alias tar="gtar"
    which colordiff &>/dev/null && alias diff="colordiff"
    which wget &>/dev/null && alias wget="wget --content-disposition"
    alias more="less"
    alias df="df -h"
    alias du="du -ch"
}
apply_aliases && unset -f apply_aliases

pws() {
    # /usr/local/bin -> /u/l/bin
    # ~/code/hxsl -> ~/c/hxsl
    # Edge case: ~/._.foo/bar -> ~/._.f/b
    print -Pn %~ | awk '{
        len = split($0,dirs,"/");
        for(i = 1; i <= len; i++) {
            if(i < len) {
                match(dirs[i], /^[._]*./)
                printf substr(dirs[i], RSTART, RLENGTH)"/"
            } else {
                print dirs[i]
            }
        }
    }'
}

pws2() {
    # 8 times slower than awk
    print -Pn %~ | perl -ne '
        my @dirs = split("/", $_);
        my $basename = pop @dirs;
        foreach $dir (@dirs) {
            print $dir =~ /^(\.*.)/;
            print "/";
        }
        print $basename;
    '
    # 10 times slower than awk
    #print -Pn %~ |perl -ne "s/(?<=\/)([._]*.)[^\/]*(?=\/)/\1/g;s/^\.$//;print;"
}


setup_highlighting() {
    local zsh_syntax_highlight
    if [[ -d ~/.config/dotfiles/zsh-syntax-highlighting ]]; then
        zsh_syntax_highlight=~/.config/dotfiles/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    elif [[ "$OSTYPE" == "linux-gnu" ]]; then
        zsh_syntax_highlight=/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        zsh_syntax_highlight=/usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    fi
    [[ -f "$zsh_syntax_highlight" ]] && . "$zsh_syntax_highlight"
}
setup_highlighting && unset -f setup_highlighting

[[ -f ~/.bash.colors ]] && . ~/.bash.colors
autoload -Uz colors && colors

if [[ $(print -Pn '%#') == '#' ]]; then
    # running as root or with privileges
    # set user color
    UC=$fg[red]
    BGUC=$bg[red]
else
    UC=$fg[cyan]
    BGUC=$bg[cyan]
fi

#PROMPT="%n@%m:%~"$'\n'"%# "  # no color
#PROMPT="%n@%m:%~"'${vcs_info_msg_0_}'$'\n'"%# "  # no color + vcs_info
#PROMPT="%{%B%}%n@%m:%~ "'${vcs_info_msg_0_}'$'\n'"%#%{$reset_color%} "  # bold + vcs_info
#PROMPT="%{$UC$BGUC%}[%{$K$BGUC%}%n %{$K$BGW%} %m%{$W$BGW%}]%{$X$HIBGK%} %~ %{$X%}"'${vcs_info_msg_0_}'$'\n'"%{$X$EMW%}%#%{$X%} "  # bash.colors color + vcs_info
PROMPT="%{$UC$BGUC%}[%{$fg[black]$BGUC%}%n %{$fg[black]$bg[white]%} %m%{$fg[white]$bg[white]%}]%{$reset_color"$'\e[0;100m'"%} %~ %{$reset_color%}"'${vcs_info_msg_0_}'$'\n'"%{$reset_color%B%}%#%{$reset_color%} "  # zsh color + vcs_info
autoload -Uz vcs_info
precmd() {
    vcs_info
    echo -en "\e]0;$(pws)\a"
    #print -Pn "\e]0;%C\a"
    #print -Pn "\e]0;%~\a"
}

zstyle ':vcs_info:*' enable git  #hg svn
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:git*' formats $'\n'"(%s) %7.7i%c%u %b%m"
zstyle ':vcs_info:git*' actionformats $'\n'"(%s|%a) %7.7i%c%u %b%m"
zstyle ':vcs_info:git*' stagedstr ' C'
zstyle ':vcs_info:git*' unstagedstr ' U'
zstyle ':vcs_info:git*:*' get-revision true
zstyle ':vcs_info:git*+set-message:*' hooks git-st git-stash

# Show remote ref name and number of commits ahead-of or behind
+vi-git-st() {
    local ahead behind remote branch detached_from
    local -a gitstatus

    # On a branch?
    branch=$(git symbolic-ref --short -q HEAD)
    # On a remote-tracking branch?
    remote=${$(git rev-parse --verify "${hook_com[branch]}@{upstream}" \
        --symbolic-full-name 2>/dev/null)/refs\/remotes\/}

    if [[ -z ${branch} ]] ; then
        detached_from=${$(git describe --tags --exact-match 2>/dev/null):-${hook_com[branch]%%.*}}
        hook_com[branch]="[detached from ${detached_from}]"
    elif [[ -n ${remote} ]] ; then
        ahead=$(git rev-list "${hook_com[branch]}@{upstream}..HEAD" 2>/dev/null | wc -l | tr -d ' ')
        (( $ahead )) && gitstatus+=( "+${ahead}" )
        behind=$(git rev-list "HEAD..${hook_com[branch]}@{upstream}" 2>/dev/null | wc -l | tr -d ' ')
        (( $behind )) && gitstatus+=( "-${behind}" )
        hook_com[branch]="${hook_com[branch]} [${remote}${gitstatus:+ ${(j:/:)gitstatus}}]"
    fi
}

# Show count of stashed changes
+vi-git-stash() {
    local -a stashes
    if [[ -s ${hook_com[base]}/.git/refs/stash ]] ; then
        stashes=$(git stash list 2>/dev/null | wc -l | tr -d ' ')
        hook_com[misc]+=" (${stashes} stashed)"
    fi
}

# Get home/end/ins/etc keys to work as expected
# create a zkbd compatible hash;
# to add other keys to this hash, see: man 5 terminfo
typeset -A key

key[Home]=${terminfo[khome]}
key[End]=${terminfo[kend]}
key[Insert]=${terminfo[kich1]}
key[Delete]=${terminfo[kdch1]}
key[Up]=${terminfo[kcuu1]}
key[Down]=${terminfo[kcud1]}
key[Left]=${terminfo[kcub1]}
key[Right]=${terminfo[kcuf1]}
key[PageUp]=${terminfo[kpp]}
key[PageDown]=${terminfo[knp]}
key[Enter]=${terminfo[kent]}  # fix OS X numpad enter

# setup key accordingly
[[ -n "${key[Home]}"     ]]  && bindkey  "${key[Home]}"     beginning-of-line
[[ -n "${key[End]}"      ]]  && bindkey  "${key[End]}"      end-of-line
[[ -n "${key[Insert]}"   ]]  && bindkey  "${key[Insert]}"   overwrite-mode
[[ -n "${key[Delete]}"   ]]  && bindkey  "${key[Delete]}"   delete-char
[[ -n "${key[Up]}"       ]]  && bindkey  "${key[Up]}"       up-line-or-history
[[ -n "${key[Down]}"     ]]  && bindkey  "${key[Down]}"     down-line-or-history
[[ -n "${key[Left]}"     ]]  && bindkey  "${key[Left]}"     backward-char
[[ -n "${key[Right]}"    ]]  && bindkey  "${key[Right]}"    forward-char
[[ -n "${key[PageUp]}"   ]]  && bindkey  "${key[PageUp]}"   beginning-of-buffer-or-history
[[ -n "${key[PageDown]}" ]]  && bindkey  "${key[PageDown]}" end-of-buffer-or-history
[[ -n "${key[Enter]}"    ]]  && bindkey  "${key[Enter]}"    accept-line

ZSH_HISTORY_SUBSTRING_SEARCH='/usr/local/opt/zsh-history-substring-search/zsh-history-substring-search.zsh'
if [[ -f "$ZSH_HISTORY_SUBSTRING_SEARCH" ]]; then
    . "$ZSH_HISTORY_SUBSTRING_SEARCH"
    [[ -n "${key[Up]}"   ]]  && bindkey  "${key[Up]}"       history-substring-search-up
    [[ -n "${key[Down]}" ]]  && bindkey  "${key[Down]}"     history-substring-search-down
fi

# Finally, make sure the terminal is in application mode, when zle is
# active. Only then are the values from $terminfo valid.
if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
    zle-line-init () {
        printf '%s' "${terminfo[smkx]}"
    }
    zle-line-finish () {
        printf '%s' "${terminfo[rmkx]}"
    }
    zle -N zle-line-init
    zle -N zle-line-finish
fi


# local config lets you update my settings without overwriting your settings
[[ -f ~/.zshrc.local ]] && . ~/.zshrc.local

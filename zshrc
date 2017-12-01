PS4='%D{%Y-%m-%d %H:%M:%S.%.} '
#set -x  # for debugging zsh startup time
#zmodload zsh/zprof  # for debugging zsh startup time
__ZSH_STARTUP_LOCAL_START_DATE=${(%):-%D{%Y-%m-%d %H:%M:%S.%.}}
#print -P '%D{%Y-%m-%d %H:%M:%S.%.}' | read __ZSH_STARTUP_LOCAL_START_DATE

[[ -z "${ORIGINAL_VARS}" ]] && ORIGINAL_VARS="$(declare -px)"
ORIGINAL_VARS="$(echo "$ORIGINAL_VARS"|grep -v ZDOTDIR)"  # Fix IntelliJ integration
typeset +x ORIGINAL_VARS
[[ -n "${FIX_PATH}" ]] && PATH="$FIX_PATH" && unset FIX_PATH
[[ -n "${RUN_WITH}" ]] && eval "$RUN_WITH" && unset RUN_WITH

SOURCE="${(%):-%N}"
while [[ -L "$SOURCE" ]]; do
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DOTFILES_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

if [[ -f ~/.histfile ]]; then
    HISTFILE=~/.histfile
else
    HISTFILE=~/.zsh_history
fi
HISTSIZE=1000000
SAVEHIST=1000000

setopt CORRECT
setopt PRINT_EXIT_VALUE
setopt EXTENDED_GLOB
setopt NO_NOMATCH
setopt NOTIFY
setopt HIST_IGNORE_SPACE
setopt HIST_IGNORE_DUPS
setopt HIST_FIND_NO_DUPS  # Ingore dupes in history search
setopt HIST_VERIFY  # print expanded history command before executing
setopt HIST_REDUCE_BLANKS
setopt APPEND_HISTORY
setopt EXTENDED_HISTORY  # write to HISTFILE with :start:elapsed;command format
setopt INC_APPEND_HISTORY  # append command to histfile immediately
setopt COMPLETE_ALIASES
setopt INTERACTIVE_COMMENTS
setopt NO_BG_NICE  # no renice background jobs
setopt LONG_LIST_JOBS  # show job number and pid when suspending
#setopt NO_CLOBBER  # prevent cat foo > bar if bar exists. Use >! instead
setopt FUNCTION_ARG_ZERO  # fill $0 with function name instead of "zsh"
setopt NO_BEEP  # no beeps
setopt PROMPT_SUBST  # variables in prompt
#setopt SH_WORD_SPLIT  # uncomment for compatibility with obscure bash scripts

setopt NO_FLOW_CONTROL  # disable ^s and ^q
stty -ixon -ixoff # disable ^s and ^q again

HISTORY_IGNORE="(&|ls|[bf]g|exit|reset|clear|which)"

REPORTTIME=1  # if a command takes longer than this many seconds of cpu time, show its time
export WORDCHARS=${WORDCHARS/\/}  # Make ctrl-w delete 1 folder at a time

bindkey -e

is_iterm() (
    # adapted from isiterm2.sh
    [[ ! -t 0 || ! -t 1 ]] && exit 1
    saved_stty="$(stty -g)"
    trap "stty '$saved_stty'; exit 1" INT
    read_bytes() { numbytes=$1; dd bs=1 count=$numbytes 2>/dev/null; }
    read_dsr() {
        dsr=""; byte="$(read_bytes 3)"
        while [[ "${byte}" != "n" ]]; do
            dsr="${dsr}${byte}"; byte="$(read_bytes 1)"
        done
        echo "${dsr/*$'\x1b['/}"
    }
    stty -echo -icanon raw 2>/dev/null
    [[ $? -ne 0 ]] && stty "$saved_stty" && exit 1
    echo -en '\x1b[1337n'; echo -en '\x1b[5n'
    version_string="$(read_dsr)"
    if [[ "${version_string}" != "0" && "${version_string}" != "3" ]]; then
        dsr="$(read_dsr)"
    else
        version_string=""
    fi
    stty "$saved_stty"
    version="${version_string/* /}"
    term="${version_string/ */}"
    MIN_VERSION=2.9.20160304; [[ $# -eq 1 ]] && MIN_VERSION="$1"
    [[ "$term" = ITERM2  && ( "$version" > "$MIN_VERSION" || "$version" = "$MIN_VERSION" ) ]]
)
[[ -e "${HOME}/.iterm2_shell_integration.zsh" ]] && is_iterm && . "${HOME}/.iterm2_shell_integration.zsh"

zstyle ':compinstall' filename "$HOME/.zshrc"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'  # case-insensitive tab completion
zstyle ':completion:*' insert-tab pending  # paste with tabs doesn't start completion
zstyle ':completion:*' use-cache on
zstyle ':completion:*' menu select  # complete with arrow key selection
#zstyle ':completion:*:*:gradle:*' gradle-inspect no  # just use simple gradle completion
zstyle ':completion:*:man:*' menu yes select
autoload -Uz compinit && compinit -i > /dev/null

[[ -d /usr/local/share/zsh-completions ]] && fpath=(/usr/local/share/zsh-completions $fpath)
[[ -d "$DOTFILES_DIR/zsh-libs/faster-vcs-info" ]] && fpath=("$DOTFILES_DIR/zsh-libs/faster-vcs-info" $fpath)

mkcd() {
    local dir="$*"
    mkdir -p "$dir" && cd "$dir"
}

cd() {
    [[ -z "$@" ]] && set_iterm_tab_rgb
    { [[ -f "$1" ]] && builtin cd "$(dirname "$1")"; } || \
    builtin cd "$@"
}

git() {
    if [[ "$1" = "commit" && "$2" = "-a"* ]]; then
        if ! git diff-index --cached --quiet HEAD --; then
            echo >&2 $'\e[0;31mERROR!\e[0m Changes are already staged. Preventing git commit -a'
            echo >&2 $'\e[0;31mERROR!\e[0m Run git commit without -a or run git reset HEAD first'
            return 1
        fi
    fi
    command git "$@"
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
    if [[ "$OSTYPE" == "linux-gnu" ]]; then
        alias ls="ls --color=auto -p"
        alias pbcopy='xsel --clipboard --input'
        alias pbpaste='xsel --clipboard --output'
    fi
    if [[ "$OSTYPE" == "cygwin" ]]; then
        alias ls="ls --color=auto -p"
        #alias pbcopy='clip'
        alias pbcopy='dd of=/dev/clipboard status=none'
        alias pbpaste='dd if=/dev/clipboard status=none'
    fi
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
    which pygmentize &>/dev/null && alias ccat="pygmentize -g"  # pip install Pygments
    alias more="less"
    alias df="df -h"
    alias du="du -ch"

    alias tmux='tmux -2'
}
apply_aliases && unset -f apply_aliases

command -v lesspipe.sh &>/dev/null && export LESSOPEN="|lesspipe.sh %s" LESS_ADVANCED_PREPROCESSOR=1

man() {
    LESS_TERMCAP_md=$'\e[01;31m' \
    LESS_TERMCAP_me=$'\e[0m' \
    LESS_TERMCAP_se=$'\e[0m' \
    LESS_TERMCAP_so=$'\e[01;44;33m' \
    LESS_TERMCAP_ue=$'\e[0m' \
    LESS_TERMCAP_us=$'\e[01;32m' \
    command man "$@"
}

findexact() {
    if [[ -z "$1" ]] || [[ -z "$2" ]]; then
        echo "Usage: $0 <path> <filename>"
        return 1
    fi
    find "$1" -name "$(echo "$2"|sed 's/\(\[\|\]\|\*\|\?\)/\\\1/g')"
}

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

    ## 55% slower than awk
    #print -Pn %~ | perl -ne '
    #    my @dirs = split("/", $_);
    #    my $basename = pop @dirs;
    #    foreach $dir (@dirs) {
    #        print $dir =~ /^(\.*.)/;
    #        print "/";
    #    }
    #    print $basename;
    #'

    ## 53% slower than awk
    #print -Pn %~ |perl -ne "s/(?<=\/)([._]*.)[^\/]*(?=\/)/\1/g;s/^\.$//;print;"
}


setup_highlighting() {
    files=(
        "$DOTFILES_DIR/zsh-libs/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
        /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    )
    for file in $files; do
        [[ -r "$file" ]] && . "$file" && return
    done
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

print_long_command_duration_preexec() {
    _date_start="$(date -u +%s)"
}
[[ -z "$preexec_functions" ]] && preexec_functions=()
preexec_functions+=print_long_command_duration_preexec

pretty_print_date_difference() {
    local date_end="$1"
    local date_start="$2"
    local date_start_iso
    local date_end_iso
    (( $date_end - $date_start < 5 )) && return
    if date --version 2>/dev/null | grep -q GNU; then
        date_start_iso="$(date -u -d @"$date_start" +%FT%TZ)"
        date_end_iso="$(date -u -d @"$date_end" +%FT%TZ)"
    else
        date_start_iso="$(date -u -r "$date_start" +%FT%TZ)"
        date_end_iso="$(date -u -r "$date_end" +%FT%TZ)"
    fi
    local wall_time=$(python -c '
import sys
now = int(sys.argv[1])
then = int(sys.argv[2])
d = divmod(now-then,86400)  # days
h = divmod(d[1],3600)  # hours
m = divmod(h[1],60)  # minutes
s = m[1]  # seconds
if d[0] > 0:
    sys.stdout.write("{}d ".format(d[0]))
sys.stdout.write("{:0>2}:{:0>2}:{:0>2}".format(h[0], m[0], s))
' $date_end $date_start)
    echo -n "Wall time: $wall_time\t"
    echo -n "Start: $date_start_iso\t"
    echo -n "Stop: $date_end_iso"
    echo
}

#PROMPT="%n@%m:%~"$'\n'"%# "  # no color
#PROMPT="%n@%m:%~"'${vcs_info_msg_0_}'$'\n'"%# "  # no color + vcs_info
PROMPT="%{%B%}%n@%m:%~ "'${vcs_info_msg_0_}'$'\n'"%#%{$reset_color%} "  # bold + vcs_info
#PROMPT="%{$UC$BGUC%}[%{$K$BGUC%}%n %{$K$BGW%} %m%{$W$BGW%}]%{$X$HIBGK%} %~ %{$X%}"'${vcs_info_msg_0_}'$'\n'"%{$X$EMW$(printf "\e[37m")%}%#%{$X%} "  # bash.colors color + vcs_info
#PROMPT="%{$UC$BGUC%}[%{$fg[black]$BGUC%}%n %{$fg[black]$bg[white]%} %m%{$fg[white]$bg[white]%}]%{$reset_color"$'\e[0;100m'"$fg[white]%} %~ %{$reset_color%}"'${vcs_info_msg_0_}'$'\n'"%{$reset_color%B%}%#%{$reset_color%} "  # zsh color + vcs_info
autoload -Uz vcs_info
print_long_command_duration_precmd() {
    _date_end="$(date -u +%s)"
    pretty_print_date_difference "$_date_end" "${_date_start:-$_date_end}"
    unset _date_start
    unset _date_end
}
set_terminal_title_short_path() {
    echo -en "\e]0;$(pws)\a"
    #print -Pn "\e]0;%C\a"
    #print -Pn "\e]0;%~\a"
}
[[ -z "$precmd_functions" ]] && precmd_functions=()
precmd_functions+=(
    print_long_command_duration_precmd
    vcs_info
    set_terminal_title_short_path)

zstyle ':vcs_info:*' enable git  #hg svn
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:git*' formats $'\n'"(%s) %7.7i%c%u %b %m"
zstyle ':vcs_info:git*' actionformats $'\n'"(%s|%a) %7.7i%c%u %b %m"
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
        #detached_from=${$(git describe --all --exact-match 2>/dev/null):-$(git rev-parse --short HEAD)}
        detached_from="$(git describe --all --always)"
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
    if git rev-parse --quiet --verify refs/stash &>/dev/null; then
        stashes=$(git rev-list --walk-reflogs --count refs/stash)
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

setup_history_search() {
    files=(
        "$DOTFILES_DIR/zsh-libs/zsh-history-substring-search/zsh-history-substring-search.zsh"
        /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
        /usr/local/opt/zsh-history-substring-search/zsh-history-substring-search.zsh
    )
    for file in $files; do
        if [[ -r "$file" ]]; then
            . "$file"
            [[ -n "${key[Up]}"   ]]  && bindkey  "${key[Up]}"    history-substring-search-up
            [[ -n "${key[Down]}" ]]  && bindkey  "${key[Down]}"  history-substring-search-down
            return
        fi
    done
}
setup_history_search && unset -f setup_history_search


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

print_zsh_startup_time() {
    echo "startup begin  \t$__ZSH_STARTUP_LOCAL_START_DATE\nstartup finish \t$__ZSH_STARTUP_LOCAL_FINISH_DATE"
}
[[ -z "$precmd_functions" ]] && precmd_functions=()
startup_timer_precmd() {
    precmd_functions=("${(@)precmd_functions:#startup_timer_precmd}")
    if [[ -z "$__ZSH_STARTUP_LOCAL_FINISH_DATE" ]]; then
        __ZSH_STARTUP_LOCAL_FINISH_DATE=${(%):-%D{%Y-%m-%d %H:%M:%S.%.}}
        #print -P '%D{%Y-%m-%d %H:%M:%S.%.}' | read __ZSH_STARTUP_LOCAL_FINISH_DATE
        command -v zprof &>/dev/null && zprof
#        print_zsh_startup_time
    fi
}
precmd_functions+=startup_timer_precmd

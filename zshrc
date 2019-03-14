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
# setopt WARN_CREATE_GLOBAL  # uncomment to warn when global variables were created in functions
# setopt WARN_NESTED_VAR

setopt NO_FLOW_CONTROL  # disable ^s and ^q
stty -ixon -ixoff # disable ^s and ^q again

HISTORY_IGNORE="(&|[ ]*|ls|bg|fg|exit|reset|clear|which)"

REPORTTIME=1  # if a command takes longer than this many seconds of cpu time, show its time
WORDCHARS=${WORDCHARS//\/}  # Make ctrl-w delete 1 folder at a time
WORDCHARS=${WORDCHARS//[\*\?\.\[\]\~\=\/\&\;\!\#\$\%\^\(\)\{\}\<\>]}  # Make ctrl-w stop deleting at these characters

## Default programs
#export BROWSER=firefox
export VISUAL=vim
export EDITOR="$VISUAL"
export SYSTEMD_EDITOR=vim

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
# case-insensitive underscore-dash-insensitive tab completion
zstyle ':completion:*' matcher-list 'm:{a-z-_}={A-Z_-}'
zstyle ':completion:*' insert-tab pending  # paste with tabs doesn't start completion
zstyle ':completion:*' use-cache on
zstyle ':completion:*' menu select  # complete with arrow key selection
#zstyle ':completion:*:*:gradle:*' gradle-inspect no  # just use simple gradle completion
zstyle ':completion:*:man:*' menu yes select
zstyle ':completion:*' rehash true  # automatically detect new executables
autoload -Uz compinit && compinit -i > /dev/null

[[ -d /usr/local/share/zsh-completions ]] && fpath=(/usr/local/share/zsh-completions $fpath)
[[ -d "$DOTFILES_DIR/zsh-libs/even-faster-vcs-info" ]] && fpath=("$DOTFILES_DIR/zsh-libs/even-faster-vcs-info" $fpath)
if [[ "$OSTYPE" == "darwin"* ]] && (( ${(@)fpath[(I)/usr/local/share/zsh/site-functions]} )); then
    # On mac with zsh and git installed from homebrew:
    # git's git completion installs to /usr/local/share/zsh/site-functions_git
    # zsh's git completion installs to /usr/local/share/zsh/functions/_git
    # git's git completion is bugged and can't handle completing long multiline aliases
    # Work around it by prioritizing zsh's built-in completions
    fpath=("${(@)fpath:#/usr/local/share/zsh/site-functions}" /usr/local/share/zsh/site-functions)
fi


# By default, the zsh help command does not show help for builtins
autoload -Uz run-help
unalias run-help &>/dev/null
alias help='PAGER="less -FX" run-help'

autoload -Uz zmv
alias zmv='noglob zmv'

# Make ^x^e edit the command line like bash
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^x^e' edit-command-line

mkcd() {
    [[ ! -z "$1" ]] && mkdir -p "$1" && builtin cd "$1"
}

mvcd() {
    (( $# > 1 )) && [[ -d "${@: -1}" ]] && mv "$@" && builtin cd "${@: -1}"
}

cd() {
    local top
    [[ "$#" -eq 0 ]] && set_iterm_tab_rgb
    { [[ "$1" = ":/" ]] && top="$(command git rev-parse --show-cdup)." && builtin cd "$top"; } || \
    { [[ -f "$1" ]] && builtin cd "$(dirname "$1")"; } || \
    builtin cd "$@"
}

swap() {
    [[ "$#" -ne 2 ]] && { echo >&2 '2 paths must be supplied'; return 1; }
    { [[ -e "$1" ]] || [[ -e "$2" ]]; } || { echo >&2 'Neither file exists'; return 1; }
    [[ "$1" = "$2" ]] && { echo >&2 "Can't swap file to itself"; return 1; }
    if [[ -e "$1" ]] && [[ -e "$2" ]]; then
        [[ -e "$1.$$" ]] && { echo >&2 'Swap temp file already exists. Aborting'; return 1; }
        mv "$1" "$1.$$" &&
        mv "$2" "$1" &&
        mv "$1.$$" "$2"
    elif [[ -e "$1" ]]; then
        mv "$1" "$2"
    elif [[ -e "$2" ]]; then
        mv "$2" "$1"
    fi
}

unalias which &>/dev/null  # Prevent system-wide which alias from breaking the which function
which() {
    { [[ -t 0 ]] && [[ -t 1 ]]; } || { builtin which "$@"; return; }
    local which_out which_exit
    which_out="$(builtin which "$@")"
    which_exit="$?"
    echo -E "$which_out" | while IFS=$'\n' read -r line; do
        if [[ "$line" = "/"* ]] && [[ -x "$line" ]]; then
            ls -la "$line"
        else
            echo -E "$line"
        fi
    done
    return "$which_exit"
}

git() {
    local code
    if [[ "$1" = "checkout" ]] && [[ "$2" = "-i"* ]]; then
        git-checkout-i "$@"; return
    fi
    if [[ "$1" = "stash" ]] && [[ "$2" = "list" ]]; then
        shift;shift;
        command git stash list --format='%C(auto)%h %gd %C(dim red)[%C(reset)%C(red)%cr%C(dim red)]%C(reset) %C(auto)%<(70,trunc)%s %C(dim cyan)<%C(reset)%C(cyan)%an%C(dim cyan)>%C(reset)' "$@"
        return
    fi
    if [[ "$1" = "grep" ]]; then
        if ! command -v perl &>/dev/null; then
            command git "$@"
            return
        fi
        command git -c color.ui=always "$@" | perl -pe 'my $truncate = 500; (my $blank = $_) =~ s/\e\[[^m]*m//g; if (length $blank > $truncate) {
            s/^((?:\e\[[^m]*m(?:.|$)(?:\e\[m)?|.|$(*SKIP)(*FAIL)){$truncate})(?=(?:\e\[[^m]*m(?:.|$)(?:\e\[m)?|.|$(*SKIP)(*FAIL)){15}).*/$1\e\[m...(truncated)/
        }'
        return
    fi
    if [[ "$1" = "commit" ]] && [[ "$2" = "-a"* ]]; then
        if ! command git diff-index --cached --quiet HEAD -- && \
            ! command git diff-files --quiet; then
            echo >&2 $'\e[0;31mERROR!\e[0m Changes are already staged. Preventing git commit -a'
            echo >&2 $'\e[0;31mERROR!\e[0m Run git commit without -a or run git reset HEAD first'
            return 1
        fi
    fi
    command git "$@"
    code="$?"
    if [[ "$1" = "commit" ]] && (( ! code )); then
        printf 'Commit subject length: '
        command git log -1 --format="%s" | tr -d '\n' | wc -m | awk '{print $1}'
    fi
    return "$code"
}

git-checkout-i() {
    local fzf one refs cmd format branches line_count term_height fzf_height fzf_tmux branch checkout_command
    command git rev-parse || return
    fzf="$(command -v fzf)"
    [[ -z "$fzf" ]] && [[ -x ~/.fzf/bin/fzf ]] && fzf=~/.fzf/bin/fzf
    if [[ -z "$fzf" ]]; then
        printf >&2 '\e[0;31mgit checkout -i requires fzf to be installed\e[0m\n'
        return 1
    fi
    fzf_tmux="$(command -v fzf-tmux)"
    [[ -z "$fzf_tmux" ]] && [[ -x ~/.fzf/bin/fzf-tmux ]] && fzf_tmux=~/.fzf/bin/fzf-tmux

    shift
    one="${1/#-i/-}"; shift; [[ "$one" != "-" ]] && set -- "$one" "$@"
    case "$1" in
        -h | --help)
            printf >&2 'Usage:\n  git checkout -i [-a] [TAIL_ARGS...]\n  git checkout -i -h\n\n'
            printf >&2 'Press enter to select a branch to check out.\nThe selected branch to check out will be added to history.\n\n'
            printf >&2 'Arguments:\n  -i: Interactive checkout\n  -a: Include non-local refs\n  TAIL_ARGS: Arguments passed to tail to limit checkout choices\n  -h: This message\n\n'
            printf >&2 'Examples:\n  git checkout -i\n  git checkout -ia\n  git checkout -i -a -10\n  git checkout -ia10\n'
            return;;
        -a) refs="--"; shift;;
        -a*) refs="--"; one="${1/#-a/-}"; shift; set -- "$one" "$@";;
        *) refs="refs/heads/"; one="${1/#-i/-}"; [[ "$#" -gt 0 ]] && shift && [[ "$one" != "-" ]] && set -- "$one" "$@";;
    esac
    # old git for-each-ref does not accept --color flag, new git for-each-ref only accepts --color flag
    command git for-each-ref --color --count=1 &>/dev/null && cmd=( command git for-each-ref --color ) || cmd=( command git -c color.ui=always for-each-ref )
    format="--format=%(refname) %00%(committerdate:format:%s)%(taggerdate:format:%s) %(color:red)%(committerdate:relative)%(taggerdate:relative)%(color:reset)%09%00%(color:yellow)%(refname:short)%(color:reset) %00%(subject)%00 %(color:reset)%(color:dim cyan)<%(color:reset)%(color:cyan)%(authorname)%(taggername)%(color:reset)%(color:dim cyan)>%(color:reset)"
    branches="$("${cmd[@]}" "$format" "$refs" |
        perl -ne 'next if /^refs\/stash /; s/^refs\/tags\/[^\x00]*\x00([^\x00]*)\x00([^\x00]*)/\1(tag) \2/ || s/^[^\x00]*\x00([^\x00]*)\x00/$1/; s/\x00([^\x00]{0,50})([^\x00]*)\x00/$1\x1b[1;30m$2\x1b[0m/; print' |
        sort -n -k1,1 | cut -d" " -f2- | tail "${@:--n+0}")" &&
        line_count=$(( $(wc -l <<< "$branches") )) &&
        term_height=$(tput lines) &&
        fzf_height=$(( line_count + 2 < term_height / 2 ? line_count + 2 : term_height / 2 )) &&
        { [[ -n "$fzf_tmux" ]] && fzf_cmd=("$fzf_tmux" -d "$fzf_height" --) || fzf_cmd=("$fzf"); } &&
        branch=$(echo "$branches" |
        "${fzf_cmd[@]}" --no-multi --reverse --tac --ansi --no-sort --height="$fzf_height") &&
        branch="$(echo "$branch" | REMOTES="$(command git remote)" perl -pe 's/\x1b\[[0-9;]*m//g; s/^([^\t]*\t)\(tag\) (.*)$/$1refs\/tags\/$2/; s/^[^\t]*\t([^ ]*).*$/$1/; my @remotes = split /\n/, $ENV{REMOTES}; foreach my $remote (@remotes) { s/^$remote\///; }')" &&
        checkout_command="$(printf 'git checkout %q\n' "$branch")" &&
        echo "$checkout_command" &&
        { { builtin history -a && builtin history -s "git checkout -i" && builtin history -s "$checkout_command" && builtin history -a; } &>/dev/null ||
            builtin print -S "$checkout_command" &>/dev/null ||
            echo "Could not save git checkout command to history"; } &&
        command git checkout "$branch"
}

add_git_alias_completion() {
    local -a git_aliases
    # Avoid 1 git invocation per alias for performance.
    # Instead, manually parse ~/.gitconfig to get all aliases at once.
    # git config --global --get alias.grep-blame &>/dev/null && _git-grep-blame() { _git-grep "$@" }
    # Avoid awk invocation for performance.
    # Instead, parse with pure zsh
    # git_aliases=(${(f)"$(awk '/^\[.*\]$/{a=0}a{sub(/^[ \t]*/,"");print}/^\[alias\]$/{a=1}' <~/.gitconfig)"})
    local -a gitconfig_lines
    local in_alias_section
    [[ -f ~/.gitconfig ]] || return
    gitconfig_lines=( ${(f)"$(<~/.gitconfig)"} )
    local line
    for line in "${gitconfig_lines[@]}"; do
        [[ $line = '['*']' ]] && in_alias_section=0
        (( in_alias_section )) && git_aliases+=("${line##[[:blank:]]##}")
        [[ $line = '[alias]' ]] && in_alias_section=1
    done
    [[ -n "${git_aliases[(r)grep-blame =*]}" ]] && _git-grep-blame() { _git-grep "$@" }
    [[ -n "${git_aliases[(r)l =*]}" ]] && _git-l() { _git-log "$@" }
    [[ -n "${git_aliases[(r)stash-staged =*]}" ]] && _git-stash-staged() { _git-stash "$@" }
    [[ -n "${git_aliases[(r)stash-unstaged =*]}" ]] && _git-stash-unstaged() { _git-stash "$@" }
    [[ -n "${git_aliases[(r)browse =*]}" ]] && _git-browse() { _git-log "$@" }
}
add_git_alias_completion; unset -f add_git_alias_completion

set_iterm_tab_rgb() {
    [[ "$TERM_PROGRAM" != "iTerm.app" ]] && return
    [[ -n "${NO_ITERM_TAB_COLOR+set}" ]] && return
    if [[ "$#" -eq 0 ]]; then
        echo -ne "\e]6;1;bg;*;default\a"  # reset
    else
        echo -ne "\e]6;1;bg;red;brightness;${1}\a\e]6;1;bg;green;brightness;${2}\a\e]6;1;bg;blue;brightness;${3}\a"
    fi
}

reset_env() {
    local command="$1"
    # assume login shell for now
    # OS X messes with the path in /etc/profile and /etc/zprofile. FIX_PATH works around this
    exec env -i ORIGINAL_VARS="$ORIGINAL_VARS" RUN_WITH="$command" "$(command -v zsh)" -d -c '
        eval "$ORIGINAL_VARS"
        FIX_PATH="$PATH" RUN_WITH="$RUN_WITH" $(command -v zsh) -l'
}

apply_aliases() {
    # ls
    if [[ "$OSTYPE" == "darwin"* ]]; then
        export CLICOLOR=1
        export LSCOLORS=gxBxhxDxfxhxhxhxhxcxcx
        alias ls="ls -Gp"
    fi
    if [[ "$OSTYPE" != "darwin"* ]]; then
        command -v xdg-open &>/dev/null && alias open="xdg-open"
    fi
    if [[ "$OSTYPE" == "linux-gnu" ]]; then
        alias ls="ls --color=auto -p"
        if uname -a | grep -q Microsoft; then
            # wsl
            alias pbcopy='clip.exe'
            alias pbpaste='powershell.exe Get-Clipboard'
        else
            alias pbcopy='xsel --clipboard --input'
            alias pbpaste='xsel --clipboard --output'
        fi
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
    alias lathr="ls -lathr"
    alias althr="ls -lathr"

    # modified commands
    command -v gtar &>/dev/null && alias tar="gtar"
    command -v colordiff &>/dev/null && alias diff="colordiff"
    command -v wget &>/dev/null && ! command wget --help 2>&1 | head -1 | grep -q BusyBox && alias wget="wget --content-disposition"
    command -v pygmentize &>/dev/null && alias ccat="pygmentize -g"  # pip install Pygments
    alias more="less"
    alias df="df -h"
    alias du="du -ch"

    alias tmux='tmux -2'
}
apply_aliases && unset -f apply_aliases

if command -v lesspipe &>/dev/null; then
    export LESSOPEN="|lesspipe %s" LESS_ADVANCED_PREPROCESSOR=1
elif command -v lesspipe.sh &>/dev/null; then
    export LESSOPEN="|lesspipe.sh %s" LESS_ADVANCED_PREPROCESSOR=1
fi

command -v direnv &>/dev/null && eval "$(direnv hook zsh)"

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
    find "$1" -name "$(printf '%q' "$2")"
}

pws() {
    # /usr/local/bin -> /u/l/bin
    # ~/code/hxsl -> ~/c/hxsl
    # Edge case: ~/._.foo/bar -> ~/._.f/b

    local cwd="$(print -Pn %~)"
    [[ "${cwd:0:1}" = '/' ]] && printf '/'
    local -a parts
    parts=(${(s:/:)cwd})
    if [[ "${#parts}" -gt 1 ]]; then
        local part
        local match mbegin mend
        for part in "${(@)parts:0:${#parts}-1}"; do
            printf '%s/' "${part/(#b)([._]#?)*/${match[1]}}"
        done
    fi
    echo "${parts[-1]}"

    # print -Pn %~ | awk -F / '{
    #     for (i = 1; i < NF; i++) {
    #         match($i, /^[._]*./)
    #         printf "%s/", substr($i, RSTART, RLENGTH)
    #     }
    #     print $NF
    # }'

    #print -Pn %~ | perl -ne '
    #    my @dirs = split m{/};
    #    my $basename = pop @dirs;
    #    foreach (@dirs) {
    #        print /^([._]*.)/, q{/};
    #    }
    #    print $basename;
    #'

    #print -Pn %~ |perl -pe 's|(?<=/)([._]*.)[^/]*(?=/)|$1|g;s|^\.$||'
}


setup_highlighting() {
    local files file
    files=(
        "$DOTFILES_DIR/zsh-libs/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
        "$DOTFILES_DIR/zsh-libs/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
        /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    )
    for file in "${files[@]}"; do
        [[ -r "$file" ]] && . "$file" && return
    done
}
setup_highlighting && unset -f setup_highlighting

[[ -f ~/.bash.colors ]] && . ~/.bash.colors
autoload -Uz colors && colors


print_long_command_duration_preexec() {
    _date_start=${(%):-%D{%s}}
}
[[ -z "$preexec_functions" ]] && preexec_functions=()
preexec_functions+=(print_long_command_duration_preexec)

print_prompt_duration_zle_accept_line() {
    # if the command was empty (just pressed enter) and if ZSH_PROMPT_PRINT_DURATION is set
    if [[ "$BUFFER" = "" ]] && [[ -n "$ZSH_PROMPT_PRINT_DURATION" ]]; then
        _prompt_date_start=${(%):-%D{%s%.}}
        [[ "$_prompt_date_start" = *"%." ]] && _prompt_date_start="$(date +%s%3N)"
    fi
}

zle_accept_line_hooks=(
    print_prompt_duration_zle_accept_line
    $'[[ "$BUFFER" != "" ]] && hash -r')

zle_accept_line_function() {
    local command_hook
    for command_hook in "${zle_accept_line_hooks[@]}"; do
        eval "$command_hook"
    done
    zle .accept-line
}
zle -N accept-line zle_accept_line_function

pretty_print_date_difference() {
    setopt LOCAL_OPTIONS NO_FORCE_FLOAT NO_C_PRECEDENCES &>/dev/null  # Old zsh does not have FORCE_FLOAT
    local date_end="$1"
    local date_start="$2"
    (( date_end - date_start < 5 )) && return
    if ( date --version 2>&1; true; ) | grep -q -e GNU -e BusyBox; then
        local date_start_iso="$(date -u -d @"$date_start" +%FT%TZ)"
        local date_end_iso="$(date -u -d @"$date_end" +%FT%TZ)"
        local date_start_local="$(date -d @"$date_start" '+%F %T')"
        local date_end_local="$(date -d @"$date_end" '+%F %T')"
    else
        local date_start_iso="$(date -u -r "$date_start" +%FT%TZ)"
        local date_end_iso="$(date -u -r "$date_end" +%FT%TZ)"
        local date_start_local="$(date -r "$date_start" '+%F %T')"
        local date_end_local="$(date -r "$date_end" '+%F %T')"
    fi
    # Avoid python call for performance
#     local wall_time="$(python -c '
# import sys
# now = int(sys.argv[1])
# then = int(sys.argv[2])
# d = divmod(now-then,86400)  # days
# h = divmod(d[1],3600)  # hours
# m = divmod(h[1],60)  # minutes
# s = m[1]  # seconds
# if d[0] > 0:
#     sys.stdout.write("{0}d ".format(d[0]))
# sys.stdout.write("{0:0>2}:{1:0>2}:{2:0>2}".format(h[0], m[0], s))
# ' "$date_end" "$date_start")"
    local wall_time
    local d=$(( (date_end - date_start) / 86400 ))
    local h=$(( (date_end - date_start) % 86400 / 3600 ))
    local m=$(( (date_end - date_start) % 86400 % 3600 / 60 ))
    local s=$(( (date_end - date_start) % 86400 % 3600 % 60 ))
    if [[ "$d" -gt 0 ]]; then
        wall_time="$(printf '%dd %.02d:%.02d:%.02d' "$d" "$h" "$m" "$s")"
    else
        wall_time="$(printf '%.02d:%.02d:%.02d' "$h" "$m" "$s")"
    fi
    {
        local local_time_zone="$(date +%Z)"
        if [[ "$local_time_zone" = UTC ]]; then
            echo "Wall time: $wall_time\tStart: $date_start_iso\tStop: $date_end_iso"
        else
            local wall_time_prefix="Wall time: $wall_time"
            local local_time_prefix="${(l(${#wall_time_prefix})( )):-Local time ($local_time_zone)}"
            echo "$wall_time_prefix\tStart: $date_start_iso\tStop: $date_end_iso"
            echo "$local_time_prefix\t     : $date_start_local\t    : $date_end_local"
        fi
    } | if command -v column &>/dev/null; then column -t -s $'\t'; else cat; fi
}


# Choose a unique color based on the hostname
# Inspired by http://zork.net/~st/jottings/Per-Host_Prompt_Colouring.html
# rgb2short function derived from https://gist.github.com/MicahElliott/719710
ssh_host_color() {  # Allows customizing the color generated by the script
    # Usage:
    # In ~/.ssh/config, put a commented Color entry for your hostname.
    # The color is a hex number representing HSL (HHSSLL)
    # Example:
    # Host mylaptop
    #   User myuser
    #   # Color 2d8ce7
    if command -v perl &>/dev/null; then
    perl -e 'sub walk{foreach my $file(@_){next if $seen{$file}++;open my $FH,"<",$file or next;
    while(<$FH>){if(/^\s*Include\s(.+)$/){walk(glob $1)}else{print}}}}walk(<~/.ssh/config>)'
    else cat ~/.ssh/config; fi |
    awk -v host="$1" 'BEGIN{x=1}END{exit x}
    tolower($1)=="host"{if(m)exit;for(i=2;i<=NF;i++){gsub(/[][().+^$]/,"\\\\&",$i);gsub(/[?]/,".",$i);gsub(/[*]/,".*",$i);if(host~"^"$i"$"&&$i!=".*")m=1}}
    m&&sub(/^[ \t]*#/,"",$0)&&tolower($1)=="color"&&tolower($2)~/[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]/{print$2;x=0;exit}'
}
HOSTBGCOLOR=$'\e[46m' # fallback to cyan background
HOSTFGCOLOR=$'\e[36m' # fallback to cyan foreground
HOSTBGTEXT=$'\e[40m'  # fallback to black background
HOSTFGTEXT=$'\e[30m'  # fallback to black foreground
HOSTHASH="$( name="$(uname -n | sed 's/\..*//')"; ssh_host_color "$name" 2>/dev/null || printf '%s\n' "$name" | if command -v md5sum &>/dev/null; then md5sum; else md5; fi )"
if command -v python &>/dev/null; then
{ IFS= read -r HOSTCOLORNUMBER; IFS= read -r HOSTTEXTNUMBER; } <<<"$(hosthash=${HOSTHASH:0:6} color_count=$(tput colors 2>/dev/null || echo 8) python -c '
import os
import colorsys
def linear_map(n, min, max, tmin, tmax):
    [n, min, max, tmin, tmax] = [float(i) for i in [n, min, max, tmin, tmax]]
    return (n - min)/(max - min) * (tmax - tmin) + tmin
hosthash = os.environ["hosthash"]
h = linear_map(int(hosthash[0:2], 16), 0, 0xff, 0, 1)
s = linear_map(int(hosthash[2:4], 16), 0, 0xff, 0.5, 1)
l = linear_map(int(hosthash[4:6], 16), 0, 0xff, 0.2, 0.8)
rgb = [0xff * i for i in colorsys.hls_to_rgb(h, l, s)]
cubelevels = [0x00, 0x5f, 0x87, 0xaf, 0xd7, 0xff]
snaps = [(x+y)/2 for x, y in list(zip(cubelevels, [0]+cubelevels))[1:]]
def rgb2short256(r, g, b):
    r, g, b = map(lambda x: len(tuple(s for s in snaps if s<x)), (r, g, b))
    return (r*36 + g*6 + b + 16,
        15 if l < 108. / 0xff or (149. / 0xff < h < 192. / 0xff and l < 166. / 0xff) else 0)
hues = [1, 3, 2, 6, 4, 5, 1]
def hl2short(h, l, color_count):
    h = hues[int(round(linear_map(h, 0, 1, 0, 6)))]
    color = h + 8 if l > .6 and color_count == 16 else h
    return color, (color == 4) * (((color_count != 8) * 8) + 7)
color_count = int(os.environ["color_count"])
colors = rgb2short256(*rgb) if color_count >= 256 else hl2short(h, l, color_count)
for c in colors: print(c)
')"  # fix vim syntax highlighting further down in the file: '
HOSTBGCOLOR=$(tput setab "$HOSTCOLORNUMBER" 2>/dev/null || printf '\e[48;5;%sm' "$HOSTCOLORNUMBER")
HOSTFGCOLOR=$(tput setaf "$HOSTCOLORNUMBER" 2>/dev/null || printf '\e[38;5;%sm' "$HOSTCOLORNUMBER")
HOSTBGTEXT=$(tput setab "$HOSTTEXTNUMBER" 2>/dev/null || printf '\e[48;5;%sm' "$HOSTTEXTNUMBER")
HOSTFGTEXT=$(tput setaf "$HOSTTEXTNUMBER" 2>/dev/null || printf '\e[38;5;%sm' "$HOSTTEXTNUMBER")
fi

if [[ $(print -Pn '%#') == '#' ]]; then
    # running as root or with privileges
    PROMPT_ROOT_FLAG="%{%b$fg[red]$bg[red]%}/%{%B$fg[white]%}!%{%b$fg[red]$bg[red]%}\\%{$reset_color%}"
else
    PROMPT_ROOT_FLAG=''
fi

PROMPT="${PROMPT_ROOT_FLAG}%{$HOSTFGCOLOR$HOSTBGCOLOR%}[%{$HOSTFGTEXT$HOSTBGCOLOR%}%n %{$fg[black]$bg[white]%} %m%{$fg[white]$bg[white]%}]%{$reset_color"$'\e[0;100m'"$fg[white]%} %~ %{$reset_color%}"'${vcs_info_msg_0_}'$'\n'"%{$reset_color%B%}%#%{$reset_color%} "  # zsh color blocks + vcs_info
#PROMPT="${PROMPT_ROOT_FLAG}%{$HOSTFGTEXT$HOSTBGCOLOR%}%n%{$HOSTFGCOLOR$HOSTBGCOLOR%}@%{$fg[black]$bg[white]%}%m%{$fg[white]$bg[white]%}:%{$reset_color"$'\e[0;100m'"$fg[white]%}%~ %{$reset_color%}"'${vcs_info_msg_0_}'$'\n'"%{$reset_color%B%}%#%{$reset_color%} "  # color blocks (half padding) + vcs_info
#PROMPT="${PROMPT_ROOT_FLAG} %{$HOSTFGTEXT$HOSTBGCOLOR%}%n%{$fg[black]$bg[black]%}@%{$fg[black]$bg[white]%}%m%{$fg[black]$bg[black]%}:%{$reset_color"$'\e[0;100m'"$fg[white]%}%~%{$reset_color%}"'${vcs_info_msg_0_}'$'\n'"%{$reset_color%B%}%#%{$reset_color%} "  # color blocks (spaced, no padding) + vcs_info
#PROMPT="${PROMPT_ROOT_FLAG}%{%B$HOSTBGTEXT$HOSTFGCOLOR%}%n@%m%{$reset_color%B%}:%~ "'${vcs_info_msg_0_}'$'\n'"%#%{$reset_color%} "  # user@host color + bold + vcs_info
#PROMPT="${PROMPT_ROOT_FLAG}%{%B%}%n@%m:%~ "'${vcs_info_msg_0_}'$'\n'"%#%{$reset_color%} "  # bold + vcs_info
#PROMPT="${PROMPT_ROOT_FLAG}%n@%m:%~"'${vcs_info_msg_0_}'$'\n'"%# "  # no color + vcs_info
#PROMPT="${PROMPT_ROOT_FLAG}%n@%m:%~"$'\n'"%# "  # no color

autoload -Uz vcs_info
print_long_command_duration_precmd() {
    _date_end=${(%):-%D{%s}}
    pretty_print_date_difference "$_date_end" "${_date_start:-$_date_end}"
    unset _date_start
    unset _date_end
}

print_prompt_duration_precmd() {
    if [[ -z "$ZSH_PROMPT_PRINT_DURATION" ]] ||
        [[ -z "$_prompt_date_start" ]] ||
        [[ "$_prompt_last_date_start" = "$_prompt_date_start" ]]; then
        return
    fi
    _prompt_last_date_start="$_prompt_date_start"
    _prompt_date_end=${(%):-%D{%s%.}}
    [[ "$_prompt_date_end" = *"%." ]] && _prompt_date_end="$(date +%s%3N)"
    _prompt_duration="$(( _prompt_date_end - _prompt_date_start ))"
    echo -e "Wall time: $_prompt_duration\tStart: $_prompt_date_start\tStop: $_prompt_date_end"
}

set_terminal_title_short_path() {
    printf '\e]0;%s\a' "$(pws)"
    #print -Pn '\e]0;%C\a'
    #print -Pn '\e]0;%~\a'
}

autoload -Uz is-at-least

# zsh before 5.0.6 has a 100% CPU bug with zle -F
if is-at-least 5.0.6; then
    async_vcs_info() {
        setopt LOCAL_OPTIONS NO_MONITOR
        if [[ "$_async_vcs_info_pid" -ne 0 ]]; then
            zle -F "$_async_vcs_info_fd"
            # Clean up the old fd
            exec {_async_vcs_info_fd}<&-
            unset _async_vcs_info_fd
            # Kill the obsolete async child
            kill -s HUP "$_async_vcs_info_pid" &>/dev/null
        fi
        coproc {
            vcs_info
            printf %s "$vcs_info_msg_0_"
        }
        _async_vcs_info_pid=$!  # Get the pid of the vcs_info coproc
        exec {_async_vcs_info_fd}<&p  # Get the vcs_info coproc output fd
        disown %?vcs_info # disown "%${(k)jobstates[(r)*:$_async_vcs_info_pid=*]}"
        zle -F $_async_vcs_info_fd async_vcs_info_handle_complete
    }
    async_vcs_info_handle_complete() {
        zle -F $1  # Unregister the handler
        local old_vcs_info_msg_0_="$vcs_info_msg_0_"
        vcs_info_msg_0_="$(<&$1)"  # Read the vcs_info data
        exec {1}<&-  # Clean up the old fd
        unset _async_vcs_info_fd
        unset _async_vcs_info_pid
        if [[ "$old_vcs_info_msg_0_" != "$vcs_info_msg_0_" ]]; then
            zle && zle .reset-prompt  # Redraw the prompt
            # use .reset-prompt instead of reset-prompt because of:
            # https://github.com/sorin-ionescu/prezto/issues/1026
        fi
    }
else
    async_vcs_info() {
        setopt LOCAL_OPTIONS NO_MONITOR
        if [[ "$_async_vcs_info_pid" -ne 0 ]]; then
            exec {_async_vcs_info_fd}<&-
            unset _async_vcs_info_fd
            kill -s HUP "$_async_vcs_info_pid" &>/dev/null
        fi
        coproc {
            vcs_info
            printf %s "$vcs_info_msg_0_"
            kill -s USR1 $$ &>/dev/null
        }
        _async_vcs_info_pid=$!  # Get the pid of the vcs_info coproc
        exec {_async_vcs_info_fd}<&p  # Get the vcs_info coproc output fd
        disown %?vcs_info # disown "%${(k)jobstates[(r)*:$_async_vcs_info_pid=*]}"
    }
    trap async_vcs_info_handle_complete USR1
    async_vcs_info_handle_complete() {
        local old_vcs_info_msg_0_="$vcs_info_msg_0_"
        vcs_info_msg_0_="$(<&$_async_vcs_info_fd)"
        exec {_async_vcs_info_fd}<&-
        unset _async_vcs_info_fd
        unset _async_vcs_info_pid
        if [[ "$old_vcs_info_msg_0_" != "$vcs_info_msg_0_" ]]; then
            zle && zle .reset-prompt  # Redraw the prompt
        fi
    }
fi


[[ -z "$precmd_functions" ]] && precmd_functions=()
precmd_functions+=(
    print_long_command_duration_precmd
    async_vcs_info
    set_terminal_title_short_path
    print_prompt_duration_precmd)

clear_vcs_info() {
    vcs_info_msg_0_=''
}
[[ -z "$chpwd_functions" ]] && chpwd_functions=()
chpwd_functions+=(clear_vcs_info)  # Get new vcs_info after cd

zstyle ':vcs_info:*' enable git  #hg svn
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:git*' formats $'\n'"(%s) %i%c%u %b %m"
zstyle ':vcs_info:git*' actionformats $'\n'"(%s|%a) %i%c%u %b %m"
zstyle ':vcs_info:git*' stagedstr ' S'
zstyle ':vcs_info:git*' unstagedstr ' U'
zstyle ':vcs_info:git*:*' get-revision true
zstyle ':vcs_info:git*+set-message:*' hooks git-st git-stash

# Show remote ref name and number of commits ahead-of or behind
+vi-git-st() {
    local ahead behind remote branch on_branch detached_from
    local -a gitstatus

    # If hook_com[revision] is already short then we can skip safely getting the short hash
    [[ "${#hook_com[revision]}" -gt 39 ]] && hook_com[revision]="$(command git rev-parse --verify -q --short=7 HEAD)"

    # On a branch? Need to check because hook_com[branch] might be a tag
    IFS='' read -r branch <"${gitdir}/HEAD"
    [[ "$branch" = "ref: refs/heads/"* ]] && on_branch=true || on_branch=false

    if [[ "$on_branch" = true ]]; then
        # On a remote-tracking branch?
        remote="${$(command git rev-parse --verify --symbolic-full-name @{u} 2>/dev/null)#refs/remotes/}"
        if [[ -n "${remote}" ]]; then
            IFS=$'\t' read -r ahead behind <<<"$(command git rev-list --left-right --count HEAD...@{u})"
            (( ahead )) && gitstatus+=( "+${ahead}" )
            (( behind )) && gitstatus+=( "-${behind}" )
            hook_com[branch]="${hook_com[branch]} [${remote}${gitstatus:+ ${(j:/:)gitstatus}}]"
        fi
    else
        detached_from="${$(command git describe --all --always 2>/dev/null):-${hook_com[revision]}}"
        hook_com[branch]="[detached from ${detached_from}]"
    fi
}

# Show count of stashed changes
+vi-git-stash() {
    local stashes stashes_exit stash_message
    stashes="$(command git rev-list --walk-reflogs --count refs/stash 2>/dev/null)"
    stashes_exit="$?"
    [[ "$stashes_exit" -ne 0 ]] && return
    [[ "$stashes" -eq 0 ]] && return
    stash_message="(${stashes} stashed)"
    hook_com[misc]="${hook_com[misc]}${hook_com[misc]:+ }(${stashes} stashed)"
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
    local files file
    files=(
        "$DOTFILES_DIR/zsh-libs/zsh-history-substring-search/zsh-history-substring-search.zsh"
        /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
        /usr/local/opt/zsh-history-substring-search/zsh-history-substring-search.zsh
    )
    for file in "${files[@]}"; do
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
    echo -e "startup begin  \t$__ZSH_STARTUP_LOCAL_START_DATE\nstartup finish \t$__ZSH_STARTUP_LOCAL_FINISH_DATE"
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
precmd_functions+=(startup_timer_precmd)

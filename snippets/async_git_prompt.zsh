# Approach comparisons for a zsh async git prompt

# Unfortunately, it seems like there is no best approach:
# file is the fastest, but uses the filesystem
# coproc is about as fast, but &p from the interacive shell can't be restored
# subshell has no side effects, but it is relatively slow

# the _timeout variants will wait synchronously for a bit to potentially avoid a redraw
# the read command used in the _timeout variants add some overhead even if vcs_info is fast

# if not using zle, kill -USR1 is sent to the parent
# if the parent receives USR1 and does not handle it, it will quit
# this matters if you do something like `exec bash` before the async vcs_info finishes

# zle before zsh 5.0.6 has a 100% CPU bug:
# https://github.com/zsh-users/zsh/commit/7e04c1a53ddada7a848753d151e18f9469788b98

# Performance:
#
# Cygwin + antivirus:
# vcs_async_no avg:                    4200ms
# vcs_async_file avg:                   410ms
# vcs_async_subshell avg:               650ms
# vcs_async_subshell_timeout avg:       680ms
# vcs_async_subshell_zle avg:           650ms
# vcs_async_subshell_zle_timeout avg:   690ms
# vcs_async_coproc avg:                 410ms
# vcs_async_coproc_zle avg:             410ms
# vcs_async_coproc_zle_timeout avg:     450ms
#
# Linux:
# vcs_async_no avg:                     40ms
# vcs_async_file avg:                    9ms
# vcs_async_subshell avg:               16ms
# vcs_async_subshell_timeout avg:       50ms
# vcs_async_subshell_zle avg:           16ms
# vcs_async_subshell_zle_timeout avg:   51ms
# vcs_async_coproc avg:                  9ms
# vcs_async_coproc_zle avg:              9ms
# vcs_async_coproc_zle_timeout avg:     45ms

# References:
# http://www.zsh.org/mla/users/2014/msg00448.html
# http://www.zsh.org/mla/users/2014/msg00204.html
# https://github.com/sorin-ionescu/prezto/issues/1026


vcs_async_no() {
    async_vcs_info() { vcs_info; }
    trap - USR1
}
vcs_async_file() {
    async_vcs_info() { async_vcs_info_file; }
    trap async_vcs_info_handle_complete_file USR1
}
vcs_async_subshell() {
    async_vcs_info() { async_vcs_info_subshell; }
    trap async_vcs_info_handle_complete_fd USR1
}
vcs_async_subshell_timeout() {
    async_vcs_info() { async_vcs_info_subshell_timeout; }
    trap async_vcs_info_handle_complete_fd_timeout USR1
}
vcs_async_subshell_zle() {
    async_vcs_info() { async_vcs_info_subshell_zle; }
    trap - USR1
}
vcs_async_subshell_zle_timeout() {
    async_vcs_info() { async_vcs_info_subshell_zle_timeout; }
    trap - USR1
}
vcs_async_coproc() {
    async_vcs_info() { async_vcs_info_coproc; }
    trap async_vcs_info_handle_complete_fd USR1
}
vcs_async_coproc_zle() {
    async_vcs_info() { async_vcs_info_coproc_zle; }
    trap - USR1
}
vcs_async_coproc_zle_timeout() {
    async_vcs_info() { async_vcs_info_coproc_zle_timeout; }
    trap - USR1
}
vcs_async_subshell_zle_timeout
ZSH_PROMPT_PRINT_DURATION=1

async_vcs_info_file() {
    if [[ "$_async_vcs_info_pid" -ne 0 ]]; then
        kill -s HUP "$_async_vcs_info_pid" &>/dev/null
    fi
    {
        vcs_info
        printf %s "$vcs_info_msg_0_" >"/tmp/zsh_prompt_$$"
        kill -s USR1 $$ &>/dev/null
    } &!
    _async_vcs_info_pid=$!
}

async_vcs_info_subshell() {
    if [[ "$_async_vcs_info_pid" -ne 0 ]]; then
        # Clean up the old fd
        exec {_async_vcs_info_fd}<&-
        unset _async_vcs_info_fd
        # Kill the obsolete async child
        kill -s HUP "$_async_vcs_info_pid" &>/dev/null
    fi
    exec {_async_vcs_info_fd}< <(
        # Tell the parent shell this subshell's pid
        sh -c 'echo $PPID'
        # Get the vcs_info line
        vcs_info
        printf %s "$vcs_info_msg_0_"
        # Notify the parent shell that work is done
        kill -s USR1 $$ &>/dev/null
    )
    command true  # Prevent issues with ctrl-c. https://github.com/zsh-users/zsh-autosuggestions/issues/364#issue-348459246
    read -ru $_async_vcs_info_fd _async_vcs_info_pid
}

async_vcs_info_subshell_timeout() {
    if [[ "$_async_vcs_info_pid" -ne 0 ]]; then
        # Clean up the old fd
        exec {_async_vcs_info_fd}<&-
        unset _async_vcs_info_fd
        # Kill the obsolete async child
        kill -s HUP "$_async_vcs_info_pid" &>/dev/null
    fi
    exec {_async_vcs_info_fd}< <(
        # Tell the parent shell this subshell's pid
        sh -c 'echo $PPID'
        # Get the vcs_info line
        vcs_info
        printf _  # Allow detecting output within the synchronous time limit
        printf %s "$vcs_info_msg_0_"
        # Notify the parent shell that work is done
        kill -s USR1 $$ &>/dev/null
    )
    command true  # Prevent issues with ctrl-c. https://github.com/zsh-users/zsh-autosuggestions/issues/364#issue-348459246
    read -ru $_async_vcs_info_fd _async_vcs_info_pid
    # Read the underscore to see if we have sync output - 35ms timeout
    read -r -t 0.035 -k 1 -u $_async_vcs_info_fd vcs_info_msg_0_
    _async_vcs_info_used_sync=$?
    [[ $_async_vcs_info_used_sync -ne 0 ]] && return
    vcs_info_msg_0_="$(<&$_async_vcs_info_fd)"
    exec {_async_vcs_info_fd}<&-
    unset _async_vcs_info_fd
    # Clean up obsolete pid
    unset _async_vcs_info_pid
    # Let _async_vcs_info_used_sync be unset by the async handler
}

async_vcs_info_subshell_zle() {
    if [[ "$_async_vcs_info_pid" -ne 0 ]]; then
        zle -F "$_async_vcs_info_fd"
        exec {_async_vcs_info_fd}<&-
        unset _async_vcs_info_fd
        kill -s HUP "$_async_vcs_info_pid" &>/dev/null
    fi
    exec {_async_vcs_info_fd}< <(
        sh -c 'echo $PPID'
        vcs_info
        printf %s "$vcs_info_msg_0_"
    )
    command true  # Prevent issues with ctrl-c. https://github.com/zsh-users/zsh-autosuggestions/issues/364#issue-348459246
    read -ru $_async_vcs_info_fd _async_vcs_info_pid
    zle -F $_async_vcs_info_fd async_vcs_info_handle_complete_zle
}

async_vcs_info_subshell_zle_timeout() {
    if [[ "$_async_vcs_info_pid" -ne 0 ]]; then
        zle -F "$_async_vcs_info_fd"
        exec {_async_vcs_info_fd}<&-
        unset _async_vcs_info_fd
        kill -s HUP "$_async_vcs_info_pid" &>/dev/null
    fi
    exec {_async_vcs_info_fd}< <(
        sh -c 'echo $PPID'
        vcs_info
        printf _  # Allow detecting output within the synchronous time limit
        printf %s "$vcs_info_msg_0_"
    )
    command true  # Prevent issues with ctrl-c. https://github.com/zsh-users/zsh-autosuggestions/issues/364#issue-348459246
    read -ru $_async_vcs_info_fd _async_vcs_info_pid
    # Read the underscore to see if we have sync output - 35ms timeout
    read -r -t 0.035 -k 1 -u $_async_vcs_info_fd vcs_info_msg_0_
    local _async_vcs_info_used_sync=$?
    [[ $_async_vcs_info_used_sync -ne 0 ]] && {
        zle -F $_async_vcs_info_fd async_vcs_info_handle_complete_zle_timeout
        return
    }
    vcs_info_msg_0_="$(<&$_async_vcs_info_fd)"
    exec {_async_vcs_info_fd}<&-
    unset _async_vcs_info_fd
    # Clean up obsolete pid
    unset _async_vcs_info_pid
}

async_vcs_info_coproc() {
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

async_vcs_info_coproc_zle() {
    setopt LOCAL_OPTIONS NO_MONITOR
    if [[ "$_async_vcs_info_pid" -ne 0 ]]; then
        zle -F "$_async_vcs_info_fd"
        exec {_async_vcs_info_fd}<&-
        unset _async_vcs_info_fd
        kill -s HUP "$_async_vcs_info_pid" &>/dev/null
    fi
    coproc {
        vcs_info
        printf %s "$vcs_info_msg_0_"
    }
    _async_vcs_info_pid=$!  # Get the pid of the vcs_info coproc
    exec {_async_vcs_info_fd}<&p  # Get the vcs_info coproc output fd
    disown %?vcs_info # disown "%${(k)jobstates[(r)*:$_async_vcs_info_pid=*]}"
    zle -F $_async_vcs_info_fd async_vcs_info_handle_complete_zle
}

async_vcs_info_coproc_zle_timeout() {
    setopt LOCAL_OPTIONS NO_MONITOR
    if [[ "$_async_vcs_info_pid" -ne 0 ]]; then
        zle -F "$_async_vcs_info_fd"
        exec {_async_vcs_info_fd}<&-
        unset _async_vcs_info_fd
        kill -s HUP "$_async_vcs_info_pid" &>/dev/null
    fi
    coproc {
        vcs_info
		printf _
        printf %s "$vcs_info_msg_0_"
    }
    _async_vcs_info_pid=$!  # Get the pid of the vcs_info coproc
    exec {_async_vcs_info_fd}<&p  # Get the vcs_info coproc output fd
    disown %?vcs_info # disown "%${(k)jobstates[(r)*:$_async_vcs_info_pid=*]}"
    read -r -t 0.035 -k 1 -u $_async_vcs_info_fd vcs_info_msg_0_
    local _async_vcs_info_used_sync=$?
    [[ $_async_vcs_info_used_sync -ne 0 ]] && {
        zle -F $_async_vcs_info_fd async_vcs_info_handle_complete_zle_timeout
        return
    }
    vcs_info_msg_0_="$(<&$_async_vcs_info_fd)"
    exec {_async_vcs_info_fd}<&-
    unset _async_vcs_info_fd
    # Clean up obsolete pid
    unset _async_vcs_info_pid
}

async_vcs_info_handle_complete_file() {
    local old_vcs_info_msg_0_="$vcs_info_msg_0_"
    vcs_info_msg_0_="$(</tmp/zsh_prompt_$$)"
    rm "/tmp/zsh_prompt_$$"
    unset _async_vcs_info_pid
    [[ "$old_vcs_info_msg_0_" != "$vcs_info_msg_0_" ]] &&
        zle && zle .reset-prompt
}

async_vcs_info_handle_complete_fd() {
    local old_vcs_info_msg_0_="$vcs_info_msg_0_"
    vcs_info_msg_0_="$(<&$_async_vcs_info_fd)"
    # Clean up the old fd
    exec {_async_vcs_info_fd}<&-
    unset _async_vcs_info_fd
    # Clean up obsolete pid
    unset _async_vcs_info_pid
    # Only redraw the prompt if the prompt has changed
    [[ "$old_vcs_info_msg_0_" != "$vcs_info_msg_0_" ]] &&
        zle && zle .reset-prompt  # Redraw the prompt
    # use .reset-prompt instead of reset-prompt because of:
    # https://github.com/sorin-ionescu/prezto/issues/1026
}

async_vcs_info_handle_complete_fd_timeout() {
    local used_sync="$_async_vcs_info_used_sync"
    unset _async_vcs_info_used_sync
    # Skip if the prompt was already handled synchronously
    [[ "$used_sync" -eq 0 ]] && return
    # Read the underscore
    read -k 1 -u $_async_vcs_info_fd vcs_info_msg_0_
    # Read the vcs_info message
    local old_vcs_info_msg_0_="$vcs_info_msg_0_"
    vcs_info_msg_0_="$(<&$_async_vcs_info_fd)"
    # Clean up the old fd
    exec {_async_vcs_info_fd}<&-
    unset _async_vcs_info_fd
    # Clean up obsolete pid
    unset _async_vcs_info_pid
    # Only redraw the prompt if the prompt has changed
    [[ "$old_vcs_info_msg_0_" != "$vcs_info_msg_0_" ]] &&
        zle && zle .reset-prompt  # Redraw the prompt
}

async_vcs_info_handle_complete_zle() {
    zle -F $1
    local old_vcs_info_msg_0_="$vcs_info_msg_0_"
    vcs_info_msg_0_="$(<&$1)"
    exec {1}<&-
    unset _async_vcs_info_fd
    unset _async_vcs_info_pid
    [[ "$old_vcs_info_msg_0_" != "$vcs_info_msg_0_" ]] &&
        zle && zle .reset-prompt
}

async_vcs_info_handle_complete_zle_timeout() {
    zle -F $1
    local old_vcs_info_msg_0_="$vcs_info_msg_0_"
    # Read the underscore
    read -k 1 -u $_async_vcs_info_fd vcs_info_msg_0_
    # Read the vcs_info message
    vcs_info_msg_0_="$(<&$1)"
    exec {1}<&-
    unset _async_vcs_info_fd
    unset _async_vcs_info_pid
    [[ "$old_vcs_info_msg_0_" != "$vcs_info_msg_0_" ]] &&
        zle && zle .reset-prompt
}



# If not running interactively, don't do anything
[[ "$-" != *i* ]] && return

[[ -f ~/.bash.colors ]] && . ~/.bash.colors
#PS1=$'\u@\h:\w\n\$ '  # no color
PS1=$'\[\e[0m\e[1m\]\u@\h:\w\n\\$ \[\e[0m\]'  # bold

# Set terminal title to abbreviated path
PROMPT_COMMAND='printf "\e]0;%s\a" "$(pwd|awk -F/ -v h="$HOME" '\''{lh=length(h);if(substr($0,1,lh)==h){$0="~"substr($0,lh+1)}for(i=1;i<NF;i++){match($i,/^[._]*./);printf"%s/",substr($i,RSTART,RLENGTH)}print$NF}'\'')"'

[[ -f ~/.bashrc.local ]] && . ~/.bashrc.local


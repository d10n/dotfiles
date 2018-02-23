
# If not running interactively, don't do anything
[[ $- != *i* ]] && return

[[ -f ~/.bash.colors ]] && . ~/.bash.colors
#PS1="\u@\h:\w\n\\$ "  # no color
PS1="\[$W\]\u@\h:\w\n\\$ \[$X\]"  # color
PROMPT_COMMAND='printf "\e]0;%s\a" "$(pwd|perl -pe '"'"'s|^\Q$ENV{HOME}\E|~|;s|(?<=/)([._]*.)[^/]*(?=/)|$1|g;s|^\.$||'"'"')"'

[[ -f ~/.bashrc.local ]] && . ~/.bashrc.local


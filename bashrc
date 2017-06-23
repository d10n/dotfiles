
# If not running interactively, don't do anything
[[ $- != *i* ]] && return

[[ -f ~/.bash.colors ]] && . ~/.bash.colors
#PS1="\u@\h:\w\n\\$ "  # no color
PS1="\[$W\]\u@\h:\w\n\\$ \[$X\]"  # color
PROMPT_COMMAND='echo -en "\033]0;$(pwd|HOME="$HOME" perl -ne '"'"'s/^\Q$ENV{HOME}\E/~/;s/(?<=\/)([._]*.)[^\/]*(?=\/)/\1/g;s/^\.$//;print;'"'"')\007"'

[[ -f ~/.bashrc.local ]] && . ~/.bashrc.local


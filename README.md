# dotfiles

Clone to `~/.config/dotfiles` and run `~/.config/dotfiles/install` or manually symlink the files you want.  
Executable files are meant to be executed instead of symlinked.

Make local customizations with:

    ~/.vimrc.local
    ~/.vimrc.plugins.local
    ~/.zshrc.local
    ~/.bashrc.local

## Overview

### .zshrc

Required usage notes:

 * To use zsh as the default shell, run `chsh -s $(which zsh)`
 * Make `.zprofile` and `.profile`


Recommended usage notes:

 * Optionally,
    * install `zsh-syntax-highlighting` to get colors while you type
    * install `zsh-history-substring-search` to make searching history easy; for example, type `gradle` and press up arrow to go through the history of all commands saying `gradle`.
 * The full path is shown in the prompt so you can stop typing `pwd`
 * When inside a git repository, a line is added to the prompt showing basic git status information so you can stop typing `git status`
    * Run `git fetch` to sync with upstream and see how many commits behind you are
 * iTerm tab color can be set with `set_iterm_tab_rgb`. Type `cd` by itself to remove the tab color
 * The prompt is bold to act as an eye magnet so you can find it quickly when scrolling up a lot
 * The prompt is multi-line to let every command you type start at the same column
 * `mkcd` makes a folder and `cd`s into it
 * Tab completion is powerful. Type `cd /u/l/b<tab>` and it will expand to `cd /usr/local/bin/`. If there is any ambiguity in the tab completion, as much will be expanded as possible.
 * Tab completion is case-insensitive if you start with a lowercase letter. For example, `cd /u/u` expands to `cd /Users/username`


### .vimrc

 * F2 toggles auto-indenting when pasting, F3 toggles line numbers, F4 toggles line wrapping
 * Home and 0 work like the Home key in Eclipse/Sublime/IntelliJ. ^ always goes to the beginning of the line.
 * It sets up NeoBundle plugins if you make the .vimrc.plugins file
 * Skim through and read the comments for more

### .vimrc.plugins

These plugins are generally useful. If you don't want to install plugins, don't make a .vimrc.plugins file. When first starting vim after saving this file, the plugins will install and you will be prompted to press enter a few times.

Features:

 * Tab completion
 * Extra color schemes
 * Sublime Text-like multiple cursors
 * Expand visual selection with +, contract with _
 * w/b/e through camelCase and under_score words with shift+w/b/e key
 * EditorConfig

### .tmux.conf

 * `|` splits vertically instead of `%`
 * `-` splits hoizontally instead of `"`


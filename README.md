# dotfiles

> ![rationale](https://imgs.xkcd.com/comics/is_it_worth_the_time.png)
>
> https://xkcd.com/1205/

To try without installing:

    docker build -t dotfiles .

    docker run --rm -it dotfiles
    # cd ~/.config/dotfiles; git l; vim; tmux; etc.

    # Or use the --volume flag to access files on your host
    docker run --rm -it --volume "$HOME":/mnt/ dotfiles
    # cd /mnt/; ls


To install:

    git clone https://gitlab.com/d10n/dotfiles.git ~/.config/dotfiles
    ~/.config/dotfiles/install
    # Or manually symlink the files and execute the executable files

To uninstall:

    find ~ -maxdepth 1 -lname ~'/.config/dotfiles/*' -print -delete

Make local customizations with:

    ~/.vimrc.local
    ~/.vimrc.plugins.local
    ~/.zshrc.local
    ~/.bashrc.local
    ~/.inputrc.local
    ~/.tmux.conf.local

Sample local files are in the example directory.

## Overview

### .zshrc

 * Color for the prompt is automatically chosen based on the computer's hostname
 * `zsh-syntax-highlighting` adds colors while you type
 * `zsh-history-substring-search` lets you type part of a previous command and press the up and down arrow keys to cycle through command history with that part
 * The full path is shown in the prompt so you can stop typing `pwd`
 * Git status is shown in the prompt so you can stop typing `git status`
 * iTerm tab color can be set with `set_iterm_tab_rgb`. Type `cd` by itself to remove the tab color
 * The prompt is bold to act as an eye magnet so you can find it quickly when scrolling up a lot
 * The prompt is multi-line to let every command you type start at the same column
 * `mkcd` makes a folder and `cd`s into it. `mvcd` moves a file and `cd`s to the destination.
 * Tab completion is powerful. Type `cd /u/l/b<tab>` and it will expand to `cd /usr/local/bin/`.
 * Tab completion is case-insensitive if you start with a lowercase letter. For example, `cd /u/u` expands to `cd /Users/username`
 * `git commit -a` is prevented if you already have staged changes
 * `git cdroot` `cd`s to the root of the repository

### git

 * `git l` for short log
 * `git d` for diff of unstaged changes
 * `git ds` for diff of staged changes
 * `git s` for short status
 * `git b` for git branch
 * `git bs` for branches, sorted by date
 * `git f` to fetch branches and tags
 * `git fp` to fetch branches and tags then pull

### .vimrc

 * F2 toggles auto-indenting when pasting, F3 toggles line numbers, F4 toggles line wrapping
 * Home and 0 work like the Home key in Eclipse/Sublime/IntelliJ. ^ always goes to the beginning of the line.
 * It sets up vim-plug plugins iff you make the .vimrc.plugins file
 * Skim through and read the comments for more

To get ctrl-pgup/ctrl-pgdn to switch vim tabs in iTerm: (via https://superuser.com/a/360103)
 * Go to iTerm / Preferences... / Profiles / Keys
 * Press the + button to add a profile shortcut
 * Use shortcut: `^Page Up`, action: "Send Escape sequence", value `[5;5~`
 * Use shortcut: `^Page Down`, action: "Send Escape sequence", value `[6;5~`


### .tmux.conf

 * `|` splits vertically instead of `%`
 * `-` splits hoizontally instead of `"`


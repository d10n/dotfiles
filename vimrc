" vim: set ts=2 sw=2:

" vim likes a Bourne compatible shell
if has('unix')
  if executable('zsh')
    set shell=zsh
  elseif executable('bash')
    set shell=bash
  else
    set shell=sh
  endif
endif

let root = '~/.vim'
" Make vim dir if it's missing (for brand-new setups)
for dir in ['backup', 'tmp', 'undo']
  if !isdirectory(expand(root.'/'.dir, 1))
    exec 'silent !mkdir -p '.root.'/'.dir
  endif
endfor

" Detect OS
if has('unix')
  let s:uname = system('echo -n `uname -s`')
else
  " Assume Windows
  let s:uname = 'Windows'
endif

if filereadable($HOME . '/.vimrc.plugins')  " Disable plugins by (re)moving ~/.vimrc.plugins
  let neobundle_src = 'https://github.com/Shougo/neobundle.vim'
  " Clone neobundle if it's missing
  if !isdirectory(expand(root, 1).'/bundle/neobundle.vim')
    exec '!git clone '.neobundle_src.' '.shellescape(expand(root.'/bundle/neobundle.vim', 1))
  endif

  " Immediately make neobundle accessible in the rtp
  if has('vim_starting')
    exec 'set runtimepath+='.root.'/bundle/neobundle.vim'
  endif

  " filetype on then off before calling neobundle fixes nonzero exit status on OS X
  filetype on
  filetype off
  call neobundle#begin(expand(root.'/bundle/'))
  filetype plugin indent on  " Required for neobundle

  " Manage neobundle with neobundle - required
  NeoBundleFetch 'Shougo/neobundle.vim'
  source ~/.vimrc.plugins
  call neobundle#end()
  NeoBundleCheck
endif

filetype plugin indent on  " Automatically detect filetypes
set nocompatible  " Use better vim defaults
set autoindent  " Copy indent from current line when starting a new line
set smartindent  " Automatically indent C-like syntax

set t_Co=256  " 256 colors
syntax on  " Syntax highlighting
if has('gui_running')
  set background=light  " Set light colorscheme defaults
  if !empty(globpath(&rtp, 'colors/solarized.vim'))
    " Avoid nonzero exit status by checking for colorscheme existence first
    silent! colo solarized
  else
    silent! colo default
    " Set the ColorColumn to something less obnoxious (may need tweaking for other color themes)
    highlight ColorColumn ctermbg=7 guibg=LightGray
  endif
else
  set background=dark  " Set dark colorscheme defaults
  if !empty(globpath(&rtp, 'colors/badwolf.vim'))
    " Avoid nonzero exit status by checking for colorscheme existence first
    silent! colo badwolf
  else
    silent! colo desert
    " Set the ColorColumn to something less obnoxious (may need tweaking for other color themes)
    highlight ColorColumn ctermbg=0 guibg=Black
  endif
endif

set shortmess=atI  " Disable vim intro message

" Make it obvious where 80 characters is
set textwidth=0  " Autowrap at this column (0 does not wrap, default)
set colorcolumn=80  " Vertical stripe at this column

" Tab completion list
"set wildmode=longest,list,full  " Multi-line completion menu
set wildmode=longest:full,full  " Single-line completion menu
set wildmenu  " Enhanced command-line completion

set tabstop=4  " Number of spaces that a tab counts for
set shiftwidth=4  " Spaces to use for each step of indent
set smarttab  " Use shfitwidth instead of tabstop at start of lines
set expandtab  " Expand tabs to spaces

set backspace=indent,eol,start  " Backspace over everything

set incsearch  " Search while typing
set hlsearch  " Highlight results
set showmatch  " Highlight matching brackets

set noerrorbells  " Stop most audio bells
set visualbell  " Enable visual bell to stop all audio bells
set t_vb=  " Make the visual bell do nothing

set scrolloff=5  " Lines to keep visible around the cursor when scrolling
"set cursorcolumn  " Highlight the column the cursor is at
"set cursorline  " Highlight the line the cursor is at

set ttyfast  " Faster terminal redrawing
set timeoutlen=500  " Shorter timeout default
"set lazyredraw  " Don't redraw while running macros
set ruler  " Show cursor position
"set virtualedit=all  " Cursor can go out of bounds
"set listchars=tab:\ \ ,eol:$,trail:~,extends:>,precedes:<
set listchars=tab:\ \ ,trail:~,extends:>,precedes:<  " What to display whitespace as
set list  " Show whitespace characters
set number  " Show line numbers
set numberwidth=5  " Line number column width
set laststatus=2  " Always show status line
set showcmd  " Show last command
set display+=lastline  " Display what can be shown of a last line longer than the window
set showmode  " Show the mode on the last line

set autochdir  " Set the cwd to the file's basedir
"set clipboard+=unnamed  " Share windows clipboard
set backup  " Make a backup before overwriting a file
set undofile  " Save and restore undo history when saving files
execute 'set backupdir='.root.'/backup'
" directory is the swap folder
execute 'set directory='.root.'/tmp'
if exists('&undodir')
  execute 'set undodir='.root.'/undo'
endif

" Fix arrow keys on Darwin
if s:uname == 'Darwin'
  execute system('echo noremap $(tput kcuu1) \<Up\>')
  execute system('echo noremap $(tput kcud1) \<Down\>')
  execute system('echo noremap $(tput kcub1) \<Left\>')
  execute system('echo noremap $(tput kcuf1) \<Right\>')
endif

" Disable entering Ex mode with Q
noremap Q <Nop>

" Keep selection after visually indenting
vnoremap < <gv
vnoremap > >gv

" Tab indent blocks
vnoremap <Tab> >gv
vnoremap <S-Tab> <gv

" Smart home key
noremap <expr> <silent> <Home> col('.') == match(getline('.'),'\S')+1 ? '0' : '^'
inoremap <silent> <Home> <C-O><Home>
" 0 is also smart home
map 0 <Home>
" Move the original 0 functionality to ^ since the new 0 replaces ^
noremap ^ 0

" Clear search highlights with esc
if has('gui_running')
  nnoremap <silent> <Esc> :nohlsearch<CR><Esc>
  nnoremap <silent> <C-c> :nohlsearch<CR><silent><C-c>
else
  "nnoremap <silent> <Esc> :nohlsearch<CR><Esc>
  augroup no_highlight
    autocmd TermResponse * nnoremap <Esc> :nohlsearch<CR><Esc>
    autocmd TermResponse * nnoremap <C-c> :nohlsearch<CR><silent><C-c>
  augroup END
end

if has('gui_running')
  set guioptions-=c  " GUI tabs
  set guioptions-=T  " No toolbar
  set guioptions+=m  " Menu bar
endif

" Prefer UTF-8 encoding
if has('multi_byte')
  if &termencoding == ''
    let &termencoding = &encoding
  endif
  set encoding=utf-8
  set fileencodings=utf-8
endif

" IME handling
"if has('multi_byte_ime') || has('xim')
"  highlight CursorIM guibg=Purple guifg=NONE
"  set iminsert=0 imsearch=0
"  if has('xim') && has('GUI_GTK')
"  "set imactivatekey=s-space
"  endif
"  inoremap <silent> <ESC> <ESC>:set iminsert=0<CR>
"endif

" Paste, copy, and line wrap toggle
set pastetoggle=<F2>
 noremap <F3> :set invlist invnumber<CR>
inoremap <F3> <C-o><F3>
 noremap <F4> :set nowrap!<CR>
inoremap <F4> <C-o><F4>

" Local config
if filereadable($HOME . '/.vimrc.local')
  source ~/.vimrc.local
endif


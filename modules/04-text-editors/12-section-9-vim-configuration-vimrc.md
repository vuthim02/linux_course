## 🔍 Section 9: Vim Configuration — .vimrc

Vim's behavior is controlled by `~/.vimrc`. Here is a professional starting config:

```vim
" ~/.vimrc — Professional sysadmin configuration
" This file controls how Vim behaves

" Essentials
set nocompatible              " Use Vim settings, not Vi
syntax on                     " Enable syntax highlighting
set number                    " Show line numbers
set ruler                     " Show cursor position
set showcmd                   " Show partial commands

" Indentation
set tabstop=4                 " Tab = 4 spaces
set shiftwidth=4              " Indent = 4 spaces
set expandtab                 " Use spaces, not tabs
set autoindent                " Copy indent from current line

" Search
set incsearch                 " Search as you type
set ignorecase                " Case-insensitive search
set smartcase                 " Case-sensitive if uppercase in search
set hlsearch                  " Highlight matches

" Editing
set backspace=indent,eol,start " Make backspace work normally
set showmatch                 " Show matching brackets

" Files
set fileformats=unix,dos,mac  " Handle different line endings
set encoding=utf-8

" Visual
set cursorline                " Highlight current line
set wildmenu                  " Tab completion for commands

" Backup (professionals keep backups)
set backupdir=~/.vim/backup   " Backup directory
set directory=~/.vim/swap     " Swap files directory
set undodir=~/.vim/undo       " Persistent undo
```

Apply changes without restarting:

```bash
:so %      # Source (reload) the current file
```





[← Previous](11-section-8-vim-visual-mode.md) | [↑ Index](index.md) | [Next →](13-section-10-vim-crash-recovery.md)

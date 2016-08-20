syntax on

set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
" set rtp+=~/.vim/bundle/Vundle.vim
" call vundle#begin()

" let Vundle manage Vundle, required
" Plugin 'gmarik/Vundle.vim'

" Plugin 'tpope/vim-fugitive'
" Plugin 'chriskempson/base16-vim'
" Plugin 'scrooloose/nerdtree'

" All of your Plugins must be added before the following line
" call vundle#end()             " required
" filetype plugin indent on     " required

" colorscheme base16-default
set background=dark
set linespace=5

if has("gui_running")
  if has("gui_macvim")
    set guifont=PT\ Mono:h18
  endif
endif

set expandtab                 " expand tabs to spaces
set ignorecase                " case-insensitive search
set incsearch                 " search as you type
set laststatus=2              " always show statusline
set list                      " show trailing whitespace
set listchars=tab:▸\ ,trail:▫
set number                    " show line numbers
set smartcase                 " case-sensitive search if any caps
set softtabstop=2             " insert mode tab and backspace use 2 spaces

set wildignore=log/**,node_modules/**,target/**,tmp/**,*.rbc
set wildmenu                  " show a navigable menu for tab completion
set wildmode=longest,list,full

" Enable basic mouse behavior such as resizing buffers.
set mouse=a
if exists('$TMUX')            " Support resizing in tmux
  set ttymouse=xterm2
endif

" keyboard shortcuts
let mapleader = ','
nnoremap <leader>t :NERDTreeToggle<CR>
nnoremap <leader>f :NERDTreeFind<CR>
noremap <silent> <leader>V :source ~/.vimrc<CR>:filetype detect<CR>:exe ":echo 'vimrc reloaded'"<CR>

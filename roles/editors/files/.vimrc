" Vundle
" ------
set nocompatible
filetype off
set rtp+=~/.vim/bundle/Vundle.vim

" Plugins declaration
call vundle#begin()
Plugin 'gmarik/Vundle.vim'
Plugin 'altercation/vim-colors-solarized'
Plugin 'JarrodCTaylor/vim-256-color-schemes'

Plugin 'bling/vim-airline'
Plugin 'scrooloose/nerdtree'
Plugin 'scrooloose/nerdcommenter'
Plugin 'kien/ctrlp.vim'
Plugin 'tpope/vim-surround'
Plugin 'airblade/vim-gitgutter'

Plugin 'ervandew/supertab'
Plugin 'Valloric/YouCompleteMe'
Plugin 'SirVer/ultisnips'
Plugin 'honza/vim-snippets'

Plugin 'klen/python-mode'
Plugin 'davidhalter/jedi-vim'

Plugin 'pangloss/vim-javascript'
Plugin 'hail2u/vim-css3-syntax'
Plugin 'mustache/vim-mustache-handlebars'
call vundle#end()

" Options
filetype plugin on
filetype indent on
set t_Co=256

syntax enable
" colorscheme honeybadger
let g:solarized_termcolors = &t_Co
let g:solarized_termtrans = 1
let g:solarized_termcolors=256
let g:solarized_visibility = "high"
let g:solarized_contrast = "high"
set background=dark
highlight clear SignColumn

set autoindent
set autoread
set backspace=indent,eol,start
set history=200
set noswapfile

let mapleader=","
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab
set cino=(0
set number
set cursorline
set showmatch
set incsearch
set hlsearch
set hidden
set nowrap
set noshowmode
set laststatus=2

" Filetypes management
" --------------------
au BufNewFile,BufRead *.json set ft=javascript

" Plugins customizations
" ----------------------
let g:airline_powerline_fonts= 1
let g:airline#extensions#tabline#enabled=1
let g:airline#extensions#tabline#buffer_nr_show=0

" make YCM compatible with UltiSnips (using supertab)
let g:ycm_key_list_select_completion = ['<C-n>', '<Down>']
let g:ycm_key_list_previous_completion = ['<C-p>', '<Up>']
let g:SuperTabDefaultCompletionType = '<C-n>'

" better key bindings for UltiSnipsExpandTrigger
let g:UltiSnipsExpandTrigger="<Tab>"
let g:UltiSnipsJumpForwardTrigger="<Tab>"
let g:UltiSnipsJumpBackwardTrigger="<S-Tab>"
let g:UltiSnipsEditSplit="vertical"

let g:mustache_abbreviations = 1

let g:syntastic_check_on_open=1                         " check for errors when file is loaded
let g:syntastic_loc_list_height=5                       " the height of the error list defaults to 10
let g:syntastic_python_checkers=['flake8']              " sets flake8 as the default for checking python files
let g:syntastic_javascript_checkers=['jshint']          " sets jshint as our javascript linter
let g:syntastic_filetype_map={ 'handlebars.html': 'handlebars' }
let g:syntastic_mode_map={ 'mode': 'active',
                         \ 'active_filetypes': [],
                         \ 'passive_filetypes': ['html', 'handlebars'] }

let NERDTreeIgnore=['\.pyc$']           " Ignores python pyc files
let g:NERDTreeShowHidden=1
map <C-e> :NERDTreeToggle<CR>

nmap <leader>T :enew<CR>                " To open a new empty buffer
nmap <Tab> :bnext<CR>                   " Move to the next buffer
nmap <S-Tab> :bprevious<CR>            " Move to the previous buffer
nmap <C-w> :bp <BAR> bd #<CR>           " Close the current buffer and move to the previous one

let g:jedi#use_tabs_not_buffers=0

let g:ctrlp_show_hidden=1
let g:ctrlp_use_caching=0
let g:ctrlp_custom_ignore = '\v[\/](transpiled)|dist|tmp|node_modules|(\.(swp|git|bak|pyc|DS_Store))$'
let g:ctrlp_working_path_mode = 0
let g:ctrlp_max_files=0
let g:ctrlp_max_height = 18
let g:ctrlp_open_multiple_files = '1vjr'
let g:ctrlp_buffer_func = { 'enter': 'MyCtrlPMappings' }
func! MyCtrlPMappings()
    nnoremap <buffer> <silent> <F6> :call <sid>DeleteBuffer()<cr>
endfunc

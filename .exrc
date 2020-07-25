set number
set autoindent
filetype indent on
set smartindent
" autocmd BufRead,BufWritePre *.sh normal gg=G
set tabstop=2
set autoread
set history=700
" filetype plugin on
" filetype indent on
set autoread
set so=3
set wildmenu
set wildmode=longest:full,full
set ruler
set cmdheight=2
set backspace=eol,start,indent
set whichwrap+=<,>,h,l
set ignorecase
set hlsearch
" set incsearch
set magic
set showmatch
set mat=2
set noerrorbells
set visualbell
set t_vb=
set tm=500
syntax enable
colo peachpuff
" colorscheme desert, delek, zellner,slate
" set background=dark
set encoding=utf8
set ffs=unix,dos,mac
" set expandtab
set noexpandtab
set smarttab
set shiftwidth=2
set lbr
set tw=1000
" set ai
" set si
set wrap
set laststatus=2
set mouse=a
nnoremap <silent><C-j> m`:silent +g/\m^\s*$/d<CR>``:noh<CR>
nnoremap <silent><C-k> m`:silent -g/\m^\s*$/d<CR>``:noh<CR>
nnoremap <silent><A-j> :set paste<CR>m`o<Esc>``:set nopaste<CR>
nnoremap <silent><A-k> :set paste<CR>m`O<Esc>``:set nopaste<CR>

inoremap <c-c> <c-o>:set nocul<cr><c-c>
:au InsertEnter * set cul
" :au InsertEnter *  hi StatusLine term=reverse ctermbg=5 gui=undercurl guisp=Magenta
:au InsertLeave * set nocul
" :au InsertLeave *  hi StatusLine term=reverse ctermfg=0 ctermbg=7 gui=bold,reverse
set tabpagemax=1000
nnoremap t <C-]>
" nmap \\ <c-]>
nnoremap <C-j> :cclose<CR>
nnoremap <C-T> :GtagsCursor<CR>
map <C-n> :cn<CR>
map <C-p> :cp<CR>
" map <C-k> Gtags-cscope<CR><CR> 
command -nargs=* Make make stumm | cwindow 3
command -nargs=* Meike make <args> | cwindow 3
inoremap <C-w> <ESC>:wa<CR>
nnoremap <C-w> :wa<CR>
map <Leader>0 <C-w>:Make<CR>
map <Leader>ß :Meike stumminst<CR>
map <Leader>? :make git<CR>
autocmd QuickFixCmdPost [^l]* nested cwindow
autocmd QuickFixCmdPost    l* nested lwindow


" Search within a scope (a {...} program block).
" Version 2010-02-28 from http://vim.wikia.com/wiki/VimTip1530

" Search within top-level block for word at cursor, or selected text.
nnoremap <F3> /<C-R>=<SID>ScopeSearch('[[',1,0)<CR><CR>
vnoremap <F3> <Esc>/<C-R>=<SID>ScopeSearch('[[',2,0)<CR><CR>gV
" Search within current block for word at cursor, or selected text.
nnoremap <F4> /<C-R>=<SID>ScopeSearch('[{', 1,0)<CR><CR>
vnoremap <F4> <Esc>/<C-R>=<SID>ScopeSearch('[{',2,0)<CR><CR>gV
" Search within current top-level block for user-entered text.
nnoremap <F2> /<C-R>=<SID>ScopeSearch('[[',0,0)<CR>
vnoremap <F2> <Esc>/<C-R>=<SID>ScopeSearch('[[',2,0)<CR><CR>
" Ersetzen
nnoremap <F5> :<C-R>=<SID>ScopeSearch('[[', 0,1)<CR>
vnoremap <F5> <Esc>:<C-R>=<SID>ScopeSearch('[[',2,1)<CR><CR>

" Return a pattern to search within a specified scope, or
" return a backslash to cancel search if scope not found.
" navigator: a command to jump to the beginning of the desired scope
" mode: 0=scope only; 1=scope+current word; 2=scope+visual selection
function! s:ScopeSearch(navigator, mode, ers)
	if a:mode == 0
		let pattern = ''
	elseif a:mode == 1
		let pattern = '\<' . expand('<cword>') . '\>'
	else
		let old_reg = getreg('@')
		let old_regtype = getregtype('@')
		normal! gvy
		let pattern = escape(@@, '/\.*$^~[')
		call setreg('@', old_reg, old_regtype)
	endif
	let saveview = winsaveview()
	execute 'normal! ' . a:navigator
	let first = line('.')
	normal %
	let last = line('.')
	normal %
	call winrestview(saveview)
	if first < last 
		if a:ers == 0
			return printf('\%%>%dl\%%<%dl%s', first-1, last+1, pattern)
		else
			return printf('%d,%ds/%s', first-1, last+1, pattern)
		endif
	endif
	return "\b"
endfunction

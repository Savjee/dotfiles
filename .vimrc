filetype plugin indent on
syntax on
set number
set re=2
set ai
highlight Comment ctermfg=green

set tabstop=4
set shiftwidth=4
set expandtab

if strftime("%H") < 19 
  set background=light
else
  set background=dark
endif

set backspace=indent,eol,start

" Set the cursor to a line when entering INSERT mode.
" Revert to block when going to NORMAL.
let &t_SI.="\e[6 q" "SI = INSERT mode
let &t_EI.="\e[2 q" "EI = NORMAL mode (ELSE)
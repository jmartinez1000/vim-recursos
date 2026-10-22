" ============================================================================
" .vimrc para programar en Rust desde la consola (Canaima / Debian)
" Requisitos: Vim >= 9.0.0438, Node.js >= 22.15, git, curl, rustup con
"             los componentes rust-analyzer y rust-src instalados.
" Instalación de vim-plug (una sola vez):
"   curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
"     https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
" Luego, dentro de Vim:  :PlugInstall
" ============================================================================

" ---- 1. Base ---------------------------------------------------------------
" Estas dos líneas van antes que cualquier complemento: la codificación debe
" estar fijada antes de que airline construya sus símbolos.
set nocompatible
set encoding=utf-8
set fileencodings=utf-8,latin1
scriptencoding utf-8

" Al existir ~/.vimrc, Vim deja de cargar defaults.vim (ruler, showcmd,
" scrolloff, etc.). Se recupera de forma explícita.
unlet! skip_defaults_vim
source $VIMRUNTIME/defaults.vim

" La tecla líder se define ANTES de cualquier mapeo que la use.
let mapleader = ' '

" ---- 2. Complementos -------------------------------------------------------
call plug#begin('~/.vim/plugged')
Plug 'preservim/nerdtree'                          " árbol de archivos
Plug 'neoclide/coc.nvim', {'branch': 'release'}    " cliente LSP (rust-analyzer)
Plug 'rust-lang/rust.vim'                          " sintaxis, rustfmt, :Cargo
Plug 'vim-airline/vim-airline'                     " barra de estado
call plug#end()

" ---- 3. Interfaz -----------------------------------------------------------
syntax enable
filetype plugin indent on
set number
set relativenumber
set hlsearch
set incsearch
set showmatch
set hidden
set signcolumn=yes
set laststatus=2
set cmdheight=2
set updatetime=300
set scrolloff=5
set nobackup
set nowritebackup

" Sin ratón: en consola pura el ratón de Vim interfiere con la selección y
" el pegado del propio terminal. Quien lo quiera, que cambie a mouse=a.
set mouse=

" Color verdadero solo si el terminal lo anuncia; en una TTY o en un
" terminal de 256 colores la opción rompe la paleta.
if has('termguicolors') && ($COLORTERM ==# 'truecolor' || $COLORTERM ==# '24bit')
  set termguicolors
endif

" ---- 4. Sangría: cuatro espacios, como exige rustfmt -----------------------
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab

" ---- 5. NERDTree -----------------------------------------------------------
nnoremap <silent> <C-n> :NERDTreeToggle<CR>
" Cambia el directorio de trabajo cuando cambia la raíz del árbol.
let g:NERDTreeChDirMode = 2
" Abrir el árbol si Vim arranca sin archivos.
autocmd VimEnter * if argc() == 0 && exists(':NERDTree') | NERDTree | endif
" Cerrar Vim si la única ventana que queda es el árbol.
autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

" ---- 6. coc.nvim: autocompletado y navegación ------------------------------
let g:coc_global_extensions = ['coc-rust-analyzer']

" Forzar el menú de completado: Ctrl-Espacio (en Vim de consola llega como <C-@>).
if has('nvim')
  inoremap <silent><expr> <C-Space> coc#refresh()
else
  inoremap <silent><expr> <C-@> coc#refresh()
endif

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1] =~# '\s'
endfunction

inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr> <S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"
inoremap <expr> <Up>    coc#pum#visible() ? coc#pum#prev(1) : "\<Up>"
inoremap <expr> <Down>  coc#pum#visible() ? coc#pum#next(1) : "\<Down>"
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#select_confirm()
      \ : "\<C-g>u\<CR>\<C-r>=coc#on_enter()\<CR>"

let g:coc_snippet_next = '<TAB>'
let g:coc_snippet_prev = '<S-TAB>'

nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
" Con líder: "rn" a secas anulaba el comando r seguido de n.
nmap <silent> <leader>rn <Plug>(coc-rename)
nmap <silent> <leader>a  <Plug>(coc-codeaction-cursor)
nmap <silent> <leader>f  <Plug>(coc-format-selected)
xmap <silent> <leader>f  <Plug>(coc-format-selected)
" Documentación flotante del símbolo bajo el cursor.
nnoremap <silent> K :call CocActionAsync('doHover')<CR>
" Recorrer diagnósticos (errores y advertencias) del compilador.
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)
" Mostrar u ocultar las pistas de tipo de rust-analyzer en el búfer actual.
nnoremap <silent> <leader>h :CocCommand document.toggleInlayHint<CR>

" ---- 7. rust.vim -----------------------------------------------------------
" Formatear con rustfmt al guardar (variable global: no requiere autocmd).
let g:rustfmt_autosave = 1

" rust.vim fija 'compiler cargo' en todo búfer .rs y, durante :make, se sitúa
" solo en el directorio del Cargo.toml más cercano. Por eso basta :make! check
" para obtener la lista quickfix con los errores del compilador.
" F5 y F6: revisar y compilar; los errores quedan en quickfix (]q y [q saltan).
nnoremap <silent> <F5> :w<CR>:silent make! check<CR>:cwindow<CR>:redraw!<CR>
nnoremap <silent> <F6> :w<CR>:silent make! build<CR>:cwindow<CR>:redraw!<CR>
" F7 y F8: ejecutar y probar. :Crun y :Ctest (rust.vim) abren cargo en una
" ventana de terminal, lo que permite interactuar con el programa.
nnoremap <silent> <F7> :w<CR>:Crun<CR>
nnoremap <silent> <F8> :w<CR>:Ctest<CR>
" Ventana quickfix: abrir, cerrar y saltar entre errores.
nnoremap <silent> <leader>q :copen<CR>
nnoremap <silent> <leader>Q :cclose<CR>
nnoremap <silent> ]q :cnext<CR>
nnoremap <silent> [q :cprevious<CR>

" ---- 8. Colores de los menús de coc ---------------------------------------
" Dentro de un autocmd para que sobrevivan a un :colorscheme posterior.
function! s:ColoresCoc() abort
  " Menú nativo de Vim (lo usa Vim cuando coc no está activo).
  highlight Pmenu       guifg=#d4be98 guibg=#32302f ctermfg=187 ctermbg=237
  highlight PmenuSel    guifg=#1d2021 guibg=#a9b665 ctermfg=234 ctermbg=143 cterm=bold gui=bold
  " Menú de completado de coc: el fondo del menú es CocFloating y la fila
  " seleccionada es CocMenuSel. Si ambos comparten tono, la selección se
  " pierde; por eso la fila activa lleva fondo verde oliva y texto oscuro.
  " (CocPmenu y CocPmenuSel, usados en la versión original, no existen.)
  highlight CocFloating guifg=#d4be98 guibg=#32302f ctermfg=187 ctermbg=237
  highlight CocMenuSel  guifg=#1d2021 guibg=#a9b665 ctermfg=234 ctermbg=143 cterm=bold gui=bold
  " Caracteres que coinciden con lo tecleado, dentro de cada candidato.
  highlight CocPumSearch guifg=#e78a4e guibg=NONE ctermfg=208 ctermbg=NONE cterm=bold gui=bold
  " Columna de detalle (firma, origen) y barra de desplazamiento del menú.
  highlight CocPumDetail guifg=#928374 guibg=NONE ctermfg=245 ctermbg=NONE
  highlight CocFloatThumb guibg=#665c54 ctermbg=241
  highlight CocList     guifg=#d4be98 guibg=#32302f ctermfg=187 ctermbg=237
  " Pistas de tipo y de parámetro que inserta rust-analyzer (": i32" junto a
  " un let, nombres de argumentos en una llamada). Por omisión coc las pinta
  " con el fondo de la columna de signos, que en muchos terminales es claro y
  " produce un bloque blanco muy llamativo. Aquí: sin fondo, gris tenue y en
  " cursiva, para que se lean como anotación y no como código.
  highlight CocInlayHint          guifg=#7c6f64 guibg=NONE ctermfg=243 ctermbg=NONE cterm=italic gui=italic
  highlight CocInlayHintType      guifg=#7c6f64 guibg=NONE ctermfg=243 ctermbg=NONE cterm=italic gui=italic
  highlight CocInlayHintParameter guifg=#7c6f64 guibg=NONE ctermfg=243 ctermbg=NONE cterm=italic gui=italic
endfunction
augroup ColoresCoc
  autocmd!
  autocmd ColorScheme * call s:ColoresCoc()
augroup END
call s:ColoresCoc()
augroup END
call s:ColoresCoc()

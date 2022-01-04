let s:state = {}
let s:state.firstview = v:null
let s:state.finalview = v:null

"
" searchx#cursor#save
"
function! searchx#cursor#save(view) abort
  let s:state.firstview = a:view
endfunction

"
" searchx#cursor#goto
"
function! searchx#cursor#goto(pos) abort
  augroup searchx-cursor-goto
    autocmd!
  augroup END

  if empty(s:state.firstview)
    let s:state.firstview = winsaveview()
  endif
  call s:cursor(a:pos[0], a:pos[1])
  let s:state.finalview = winsaveview()

  augroup searchx-cursor-goto
    autocmd!
    autocmd CursorMoved * call s:on_cursor_moved()
  augroup END
endfunction

"
" searchx#cursor#mark
"
function! searchx#cursor#mark() abort
  if empty(s:state.firstview)
    return
  endif

  augroup searchx-cursor-goto
    autocmd!
  augroup END

  let l:view = winsaveview()
  call winrestview(s:state.firstview)
  normal! m`
  call winrestview(l:view)

  let s:state = {}
  let s:state.firstview = v:null
  let s:state.finalview = v:null
endfunction

"
" s:on_cursor_moved
"
function! s:on_cursor_moved() abort
  let l:view = winsaveview()
  let l:same = v:true
  let l:same = l:same && l:view.lnum == s:state.finalview.lnum
  let l:same = l:same && l:view.col == s:state.finalview.col
  if l:same
    return
  endif
  call searchx#cursor#mark()
endfunction

"
" cursor
"
function! s:cursor(lnum, col) abort
  let l:above = line('w0') + g:searchx.scrolloff
  let l:below = line('w$') - g:searchx.scrolloff
  if a:lnum < l:above
    execute printf('noautocmd silent normal! %s', repeat("\<C-y>", l:above - a:lnum))
  elseif l:below < a:lnum
    execute printf('noautocmd silent normal! %s', repeat("\<C-e>", a:lnum - l:below))
  endif
  call cursor(a:lnum, a:col)
endfunction

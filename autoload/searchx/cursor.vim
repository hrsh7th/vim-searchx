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
  call cursor(a:pos[0], a:pos[1])
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


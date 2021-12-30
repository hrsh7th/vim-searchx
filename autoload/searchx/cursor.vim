let s:state = {}
let s:state.firstview = v:null
let s:state.finalview = v:null

"
" searchx#cursor#set_firstview
"
function! searchx#cursor#set_firstview(view) abort
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
    autocmd CursorMoved * call s:save()
  augroup END
endfunction

"
" s:save
"
function! s:save() abort
  let l:view = winsaveview()
  let l:same = v:true
  let l:same = l:same && l:view.lnum == s:state.finalview.lnum
  let l:same = l:same && l:view.col == s:state.finalview.col
  if l:same
    return
  endif

  augroup searchx-cursor-goto
    autocmd!
  augroup END

  call winrestview(s:state.firstview)
  normal! m`
  call winrestview(l:view)

  let s:state = {}
  let s:state.firstview = v:null
  let s:state.finalview = v:null
endfunction


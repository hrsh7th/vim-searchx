let s:AcceptReason = {}
let s:AcceptReason.Marker = 1
let s:AcceptReason.Return = 2

let s:Direction = {}
let s:Direction.Prev = 0
let s:Direction.Next = 1

let s:state = {}
let s:state.direction = s:Direction.Next
let s:state.firstview = winsaveview()
let s:state.matches = { 'matches': [], 'current': v:null }
let s:state.accept_reason = s:AcceptReason.Marker

"
" searchx#run
"
function! searchx#run(...) abort
  " initialize.
  let s:state.direction = get(a:000, 0, s:detect_direction())
  let s:state.firstview = winsaveview()
  let s:state.accept_reason = s:AcceptReason.Return
  call searchx#cursor#set_firstview(s:state.firstview)
  let @/ = ''
  let v:hlsearch = v:true

  " start. 
  augroup searchx-run
    autocmd!
    autocmd CmdlineChanged * call s:on_input()
  augroup END
  doautocmd <nomodeline> User SearchxEnter
  let l:return = input('/')
  doautocmd <nomodeline> User SearchxLeave
  augroup searchx-run
    autocmd!
  augroup END

  " finalize. 
  call s:clear()
  if l:return ==# ''
    call winrestview(s:state.firstview)
    doautocmd <nomodeline> User SearchxCancel
  else
    if index([s:AcceptReason.Marker], s:state.accept_reason) >= 0
      call feedkeys("\<Cmd>let v:hlsearch = v:false\<CR>", 'n')
      doautocmd <nomodeline> User SearchxAcceptMarker
    else
      call feedkeys("\<Cmd>let v:hlsearch = v:true\<CR>", 'n')
      doautocmd <nomodeline> User SearchxAcceptReturn
    endif
    doautocmd <nomodeline> User SearchxAccept
  endif
endfunction

"
" searchx#clear
"
function! searchx#clear() abort
  call s:clear()
endfunction

"
" searchx#search_next
"
function searchx#search_next() abort
  call s:goto_next()
endfunction

"
" searchx#search_prev
"
function searchx#search_prev() abort
  call s:goto_prev()
endfunction

"
" s:search
"
function! s:goto_next() abort
  let l:pos = s:search('wzn')
  if !empty(l:pos)
    call s:goto(l:pos)
  endif
endfunction

"
" s:search_prev
"
function! s:goto_prev() abort
  let l:pos = s:search('wbn')
  if !empty(l:pos)
    call s:goto(l:pos)
  endif
endfunction

"
" s:goto
"
function! s:goto(pos) abort
  call searchx#cursor#goto(a:pos)
  let s:state.matches = s:find_matches(@/, a:pos)
  if mode(1) ==# 'c'
    call s:refresh({ 'marker': v:true, 'incsearch': v:true })
  else
    call searchx#async#step([
    \   { next -> [s:refresh({ 'marker': v:false, 'incsearch': v:true }), searchx#async#timeout('goto', 500, next)] },
    \   { next -> [s:refresh({ 'marker': v:false, 'incsearch': v:false }), next()] },
    \   { next -> [feedkeys("\<Cmd>let v:hlsearch = v:true\<CR>", 'n'), next()] },
    \ ])
  endif
endfunction

"
" s:search
"
function! s:search(expr) abort
  if @/ ==# ''
    return v:null
  endif
  let l:pos = searchpos(@/, a:expr)
  if l:pos[0] != 0
    return l:pos
  endif
  return v:null
endfunction

"
" s:detect_direction
"
function! s:detect_direction() abort
  let l:curpos = getcurpos()[1:2]
  let l:above = l:curpos[0] - line('w0')
  let l:below = line('w$') - l:curpos[0]
  return l:above > l:below ? s:Direction.Prev : s:Direction.Next
endfunction


"
" on_input
"
function! s:on_input() abort
  try
    let l:input = g:searchx.convert(getcmdline())
    if @/ ==# l:input
      return
    endif

    " Check marker.
    if strlen(l:input) > 0
      let l:index = index(g:searchx.markers, l:input[strlen(l:input) - 1])
      if l:index >= 0
        for l:match in s:state.matches.matches
          if l:match.marker ==# g:searchx.markers[l:index]
            call searchx#cursor#goto([l:match.lnum, l:match.col])
            let s:state.accept_reason = s:AcceptReason.Marker
            call feedkeys("\<CR>", 'n')
            return
          endif
        endfor
      endif
    endif

    " Check backspace.
    if strlen(l:input) < strlen(@/)
      call winrestview(s:state.firstview)
    endif

    " Update search pattern.
    let @/ = l:input

    " Update view state.
    let s:state.matches = s:find_matches(@/, [s:state.firstview.lnum, s:state.firstview.col + 1])
    call s:refresh({ 'marker': v:true })

    " Search for out-of-window match via native `searchpos`.
    if empty(s:state.matches.matches) && s:state.matches.current is v:null
      if s:state.direction == s:Direction.Next
        call s:goto_next()
      else
        call s:goto_prev()
      endif
    else
      " Move to current match.
      if s:state.matches.current isnot v:null
        call searchx#cursor#goto([s:state.matches.current.lnum, s:state.matches.current.col])
      endif
    endif
  catch /.*/
    echomsg string({ 'exception': v:exception, 'throwpoint': v:throwpoint })
  endtry
endfunction

"
" refresh
"
function s:refresh(...) abort
  call s:clear()

  let l:option = get(a:000, 0, {})
  for l:match in s:state.matches.matches
    if get(l:option, 'incsearch', v:true)
      if l:match.current
        call searchx#highlight#set_incsearch(l:match)
      endif
    endif

    if get(l:option, 'marker', v:true)
      call searchx#highlight#add_marker(l:match)
    endif
  endfor
  let v:hlsearch = len(s:state.matches.matches) > 0

  redraw
endfunction

"
" clear
"
function s:clear() abort
  call searchx#highlight#clear()
  let v:hlsearch = v:false
endfunction

"
" find_matches
"
function! s:find_matches(input, curpos) abort
  let l:lnum_s = line('w0')
  let l:lnum_e = line('w$')
  let l:texts = getbufline('%', l:lnum_s, l:lnum_e)
  let l:next = v:null
  let l:prev = v:null
  let l:matches = []
  for l:i in range(0, len(l:texts) - 1)
    let l:text = l:texts[l:i]

    let l:off = 0
    while l:off < strlen(l:text)
      let l:m = matchstrpos(l:text, a:input, l:off, 1)
      if l:m[0] ==# ''
        break
      endif
      
      let l:match = {
      \   'id': len(l:matches) + 1,
      \   'lnum': l:lnum_s + l:i,
      \   'col': l:m[1] + 1,
      \   'end_col': l:m[2] + 1,
      \   'marker': get(g:searchx.markers, len(l:matches), v:null),
      \   'current': v:false,
      \ }
      if empty(l:next) && (a:curpos[0] < l:match.lnum || a:curpos[0] == l:match.lnum && a:curpos[1] <= l:match.col)
        let l:next = l:match
      endif
      if a:curpos[0] > l:match.lnum || a:curpos[0] == l:match.lnum && a:curpos[1] >= l:match.col
        let l:prev = l:match
      endif
      call add(l:matches, l:match)
      let l:off = l:match.end_col
    endwhile
  endfor

  let l:next = empty(l:next) ? l:prev : l:next
  let l:prev = empty(l:prev) ? l:next : l:prev
  let l:current = s:state.direction == s:Direction.Next ? l:next : l:prev
  for l:match in l:matches
    if l:match is l:current
      let l:match.current = v:true
      break
    endif
  endfor

  return { 'matches': l:matches, 'current': l:current }
endfunction


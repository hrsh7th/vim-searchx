let s:AcceptReason = {}
let s:AcceptReason.Marker = 1
let s:AcceptReason.Return = 2

let s:Direction = {}
let s:Direction.Prev = 0
let s:Direction.Next = 1

let s:state = {}
let s:state.direction = s:Direction.Next
let s:state.firstview = v:null
let s:state.matches = { 'matches': [], 'current': v:null }
let s:state.accept_reason = s:AcceptReason.Marker

let s:paused = v:false

"
" searchx#run
"
function! searchx#run(...) abort
  augroup searchx-run
    autocmd!
    autocmd CmdlineChanged * call s:on_input()
  augroup END
  let s:state.direction = get(a:000, 0, s:detect_direction())
  let s:state.firstview = winsaveview()
  let s:state.accept_reason = s:AcceptReason.Return
  let v:hlsearch = v:true
  try
    let l:return = input('/')
  catch /.*/
    echomsg string({ 'exception': v:exception, 'throwpoint': v:throwpoint })
  finally
    augroup searchx-run
      autocmd!
    augroup END

    call s:clear()

    if l:return ==# ''
      if !empty(s:state.firstview)
        call winrestview(s:state.firstview)
      endif
    elseif s:state.accept_reason == s:AcceptReason.Marker
      call feedkeys("\<Cmd>let v:hlsearch = v:false\<CR>", 'n')
    else
      call feedkeys("\<Cmd>let v:hlsearch = v:true\<CR>", 'n')
    endif
  endtry
endfunction

"
" searchx#clear
"
function! searchx#clear() abort
  call s:clear()
endfunction

"
" searchx#next
"
function searchx#next() abort
  call s:goto('zn')
endfunction

"
" searchx#prev
"
function searchx#prev() abort
  call s:goto('bn')
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
" s:goto
"
function! s:goto(dir) abort
  if getreg('/') ==# ''
    return
  endif

  let l:pos = searchpos(getreg('/'), a:dir)
  if l:pos[0] != 0
    call cursor(l:pos[0], l:pos[1])
    let s:state.matches = s:find_matches(getreg('/'), l:pos)
    call s:refresh({ 'marker': mode(1) ==# 'c', 'incsearch': mode(1) ==# 'c' })
  endif
endfunction

function! searchx#_pause() abort
  let s:paused = v:true
endfunction

function! searchx#_resume() abort
  let s:paused = v:false
  call s:on_input()
endfunction

"
" on_input
"
function! s:on_input() abort
  if s:paused
    return
  endif
  try
    let l:input = g:searchx.convert(getcmdline())
    if getreg('/') ==# l:input
      return
    endif

    " Check marker.
    if strlen(l:input) > 0
      let l:index = index(g:searchx.markers, l:input[strlen(l:input) - 1])
      if l:index >= 0
        for l:match in s:state.matches.matches
          if l:match.marker ==# g:searchx.markers[l:index]
            call cursor(l:match.lnum, l:match.col)
            let s:state.accept_reason = s:AcceptReason.Marker
            call feedkeys("\<CR>", 'n')
            return
          endif
        endfor
      endif
    endif

    " Update view state.
    if strlen(getreg('/')) > strlen(l:input)
      call winrestview(s:state.firstview)
    endif
    let s:state.matches = s:find_matches(l:input, [s:state.firstview.lnum, s:state.firstview.col])
    if g:searchx.fuzzy
      if len(s:state.matches.matches) == 0 && strlen(getreg('/')) < strlen(l:input)
        let l:input = getreg('/') .. (stridx(getreg('/'), '\ze') == -1 ? '\ze' : '') .. '.\{-}' .. strpart(l:input, strlen(getreg('/')))
        let s:state.matches = s:find_matches(l:input, [s:state.firstview.lnum, s:state.firstview.col])
        call searchx#_pause()
        call feedkeys("\<C-u>" .. l:input .. "\<Cmd>call searchx#_resume()\<CR>", 'n')
      endif
    endif
    call setreg('/', l:input)
    call s:refresh({ 'marker': v:true })

    " Search for out-of-window match via native `searchpos`.
    if empty(s:state.matches.matches) && s:state.matches.current is v:null
      if s:state.direction == s:Direction.Next
        call searchx#next()
      else
        call searchx#prev()
      endif
    else
      " Move to current match.
      if s:state.matches.current isnot v:null
        call cursor(s:state.matches.current.lnum, s:state.matches.current.col)
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
    if s:state.matches.current is l:match && get(l:option, 'incsearch', v:true)
      call searchx#highlight#set_incsearch(l:match)
    else
      if get(l:option, 'marker', v:true)
        call searchx#highlight#set_marker(l:match)
      endif
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
  return { 'matches': l:matches, 'current': l:current }
endfunction


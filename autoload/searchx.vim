let s:AcceptReason = {}
let s:AcceptReason.Marker = 1
let s:AcceptReason.Return = 2

let s:state = {}
let s:state.timer = -1
let s:state.is_next = v:true
let s:state.execute_curpos = [-1, -1]
let s:state.matches = { 'matches': [], 'current': v:null }
let s:state.accept_reason = s:AcceptReason.Marker

"
" searchx#run
"
function! searchx#run(...) abort
  let s:state.timer = timer_start(100, { -> s:on_input() }, { 'repeat': -1 })
  let s:state.is_next = get(a:000, 0, 1) == 1
  let s:state.execute_curpos = getcurpos()[1:2]
  let s:state.accept_reason = s:AcceptReason.Return
  let v:hlsearch = v:true
  try
    let l:return = input('/')
  catch /.*/
    echomsg string({ 'exception': v:exception, 'throwpoint': v:throwpoint })
  finally
    call timer_stop(s:state.timer)
    call s:clear()

    if l:return ==# ''
      call cursor(s:state.execute_curpos[0], s:state.execute_curpos[1])
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

"
" on_input
"
function! s:on_input() abort
  try
    let l:input = getcmdline()
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
    call setreg('/', l:input)
    let s:state.matches = s:find_matches(getreg('/'), s:state.execute_curpos)
    call s:refresh({ 'marker': v:true })

    " Search for out-of-window match via native `searchpos`.
    if empty(s:state.matches.matches) && s:state.matches.current is v:null
      if s:state.is_next
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
  let v:hlsearch = v:true

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
  let l:curpos = getcurpos()[1:2]
  let l:saved_scrolloff = &scrolloff
  let l:saved_sidescrolloff = &sidescrolloff
  let &scrolloff = 0
  let &sidescrolloff = 0

  let l:next = v:null
  let l:prev = v:null
  let l:matches = []
  try
    call cursor(line('w0'), 1)
    let l:stopline = line('w$')
    while v:true
      let l:pos = searchpos(a:input, 'Wzn', l:stopline, 1000)
      if l:pos[0] == 0
        break
      endif
      call cursor(l:pos[0], l:pos[1])
      let l:m = matchstrpos(getline(l:pos[0]), a:input, l:pos[1] - 1, 1)
      if l:m[0] == ''
        continue
      endif

      let l:match = {
      \   'id': len(l:matches) + 1,
      \   'lnum': l:pos[0],
      \   'col': l:pos[1],
      \   'end_col': l:pos[1] + (l:m[2] - l:m[1]),
      \   'marker': get(g:searchx.markers, len(l:matches), v:null),
      \ }
      if empty(l:next) && (a:curpos[0] < l:match.lnum || a:curpos[0] == l:match.lnum && a:curpos[1] <= l:match.col)
        let l:next = l:match
      endif
      if a:curpos[0] > l:match.lnum || a:curpos[0] == l:match.lnum && a:curpos[1] >= l:match.col
        let l:prev = l:match
      endif
      call add(l:matches, l:match)
    endwhile
  catch /.*/
  finally
    call cursor(l:curpos[0], l:curpos[1])
    let &scrolloff = l:saved_scrolloff
    let &sidescrolloff = l:saved_sidescrolloff
  endtry

  let l:next = empty(l:next) ? l:prev : l:next
  let l:prev = empty(l:prev) ? l:next : l:prev
  let l:current = s:state.is_next ? l:next : l:prev
  return { 'matches': l:matches, 'current': l:current }
endfunction


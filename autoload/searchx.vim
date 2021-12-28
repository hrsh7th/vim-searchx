let s:state = {}
let s:state.timer = -1
let s:state.is_next = v:true
let s:state.execute_curpos = [-1, -1]
let s:state.current_curpos = [-1, -1]
let s:state.matches = { 'matches': [], 'current': v:null }

let s:auto_accept = v:false

"
" searchx#run
"
function! searchx#run(...) abort
  let s:state.timer = timer_start(100, { -> s:on_input() }, { 'repeat': -1 })
  let s:state.is_next = get(a:000, 0, 1) == 1
  let s:state.execute_curpos = getcurpos()[1:2]
  let s:state.current_curpos = getcurpos()[1:2]
  let s:auto_accept = v:false
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
    elseif !s:auto_accept
      call s:refresh({ 'marker': v:false, 'incsearch': v:false, })
      call feedkeys("\<Cmd>let v:hlsearch = v:true\<CR>", 'n')
    else
      call feedkeys("\<Cmd>let v:hlsearch = v:false\<CR>", 'n')
    endif
  endtry
endfunction

"
" searchx#select
"
function! searchx#select() abort
  call s:clear()
  let s:state.current_curpos = getcurpos()[1:2]
  let s:state.matches = s:find_matches(getreg('/'))
  call s:refresh({ 'incsearch': v:false })
  redraw
  let l:mode = mode(1)
  let l:char = nr2char(getchar())
  for l:match in s:state.matches.matches
    if l:match.marker ==# l:char
      call cursor(l:match.lnum, l:match.col)
      if mode() ==# 'c'
        let s:auto_accept = v:true
        call feedkeys("\<CR>", 'n')
      else
        call s:clear()
      endif
      return
    endif
  endfor
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
" searchx#clear
"
function! searchx#clear() abort
  call s:clear()
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
    let s:state.current_curpos = l:pos
    call s:clear()
    let s:state.matches = s:find_matches(getreg('/'))
    call s:refresh({ 'marker': mode(1) ==# 'c', 'incsearch': mode(1) ==# 'c' })
    redraw
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

    if strlen(l:input) > 0
      let l:index = index(g:searchx.markers, l:input[strlen(l:input) - 1])
      if l:index >= 0
        for l:match in s:state.matches.matches
          if l:match.marker ==# g:searchx.markers[l:index]
            let s:auto_accept = v:true
            call cursor(l:match.lnum, l:match.col)
            call feedkeys("\<CR>", 'n')
            return
          endif
        endfor
      endif
    endif

    call setreg('/', l:input)
    call s:clear()
    let s:state.current_curpos = deepcopy(s:state.execute_curpos)
    let s:state.matches = s:find_matches(getreg('/'))

    if empty(s:state.matches.matches) && s:state.matches.current is v:null
      if s:state.is_next
        call searchx#next()
      else
        call searchx#prev()
      endif
    else
      if s:state.matches.current isnot v:null
        call cursor(s:state.matches.current.lnum, s:state.matches.current.col)
        let s:state.current_curpos = [s:state.matches.current.lnum, s:state.matches.current.col]
      endif
      call s:refresh({ 'marker': v:true })
    endif
    redraw
  catch /.*/
    echomsg string({ 'exception': v:exception, 'throwpoint': v:throwpoint })
  endtry
endfunction

"
" refresh
"
function s:refresh(...) abort
  let v:hlsearch = v:true
  let l:option = get(a:000, 0, {})
  for l:match in s:state.matches.matches
    if s:state.matches.current is l:match && get(l:option, 'incsearch', v:true)
      call searchx#highlight#incsearch(l:match)
    else
      if get(l:option, 'marker', v:true)
        call searchx#highlight#marker(l:match)
      endif
    endif
  endfor
endfunction

"
" clear
"
function s:clear() abort
  for l:match in s:state.matches.matches
    call searchx#highlight#remove(l:match)
  endfor
  let v:hlsearch = v:false
endfunction

"
" find_matches
"
function! s:find_matches(input) abort
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

      if empty(l:next) && (s:state.current_curpos[0] < l:match.lnum || s:state.current_curpos[0] == l:match.lnum && s:state.current_curpos[1] <= l:match.col)
        let l:next = l:match
      endif
      if s:state.current_curpos[0] > l:match.lnum || s:state.current_curpos[0] == l:match.lnum && s:state.current_curpos[1] >= l:match.col
        let l:prev = l:match
      endif
      call add(l:matches, l:match)
      let l:off = l:match.end_col
    endwhile
  endfor
  let l:next = empty(l:next) ? l:prev : l:next
  let l:prev = empty(l:prev) ? l:next : l:prev
  let l:current = s:state.is_next ? l:next : l:prev
  return { 'matches': l:matches, 'current': l:current }
endfunction


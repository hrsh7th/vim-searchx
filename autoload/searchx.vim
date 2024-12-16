let s:AcceptReason = {}
let s:AcceptReason.Marker = 1
let s:AcceptReason.Return = 2

let s:Direction = {}
let s:Direction.Prev = 0
let s:Direction.Next = 1

let s:state = {}
let s:state.prompt = v:false
let s:state.direction = s:Direction.Next
let s:state.firstview = winsaveview()
let s:state.matches = { 'matches': [], 'current': v:null }
let s:state.accept_reason = s:AcceptReason.Marker
let s:state.prompt_emptily = v:true
let s:state.convert = g:searchx.convert

"
" searchx#start
"
function! searchx#start(...) abort
  let l:option = get(a:000, 0, {})

  " initialize.
  let s:state.direction = has_key(l:option, 'dir') ? l:option.dir : s:detect_direction()
  let s:state.firstview = winsaveview()
  let s:state.accept_reason = s:AcceptReason.Return
  let s:state.convert = get(l:option, 'convert', g:searchx.convert)
  let @/ = ''
  call searchx#searchundo#searchforward(s:state.direction)
  call searchx#searchundo#hlsearch(v:true)
  call searchx#cursor#save(s:state.firstview)

  " start.
  augroup searchx-run
    autocmd!
    autocmd CmdlineChanged * call s:on_input()
  augroup END

  doautocmd <nomodeline> User SearchxEnter

  " Update statusline if enter cmdline mode via `input(...)`.
  call feedkeys("\<Cmd>redrawstatus\<CR>", 'ni')

  let s:state.prompt = v:true
  let l:return = input(s:state.direction == 1 ? '/' : '?')

  let s:state.prompt = v:false
  let s:state.prompt_emptily = v:true

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
    call histadd('/', @/)
    call searchx#cursor#mark()
    doautocmd <nomodeline> User SearchxAccept
    if index([s:AcceptReason.Marker], s:state.accept_reason) >= 0
      doautocmd <nomodeline> User SearchxAcceptMarker
      call searchx#searchundo#hlsearch(v:false)
    else
      doautocmd <nomodeline> User SearchxAcceptReturn
      call searchx#searchundo#hlsearch(v:true)
    endif
  endif
endfunction

"
" searchx#select
"
function! searchx#select() abort
  let s:state.matches = s:find_matches(@/, getcurpos()[1:2])
  call s:refresh({ 'marker': v:true, 'incsearch': v:false })

  function! s:callback(timer) abort closure
    if getchar(1) != 0
      return
    endif
    call timer_stop(a:timer)

    let l:char = nr2char(getchar())
    call s:clear()
    for l:match in s:state.matches.matches
      if l:match.marker ==# l:char
        return s:accept_marker(l:match)
      endif
    endfor
  endfunction
  call timer_start(0, function('s:callback'), { 'repeat': -1 })
endfunction

"
" searchx#clear
"
function! searchx#clear() abort
  call s:clear()
endfunction

"
" searchx#next_dir
"
function searchx#next_dir() abort
  if v:searchforward == 0
    return searchx#prev()
  endif
  call searchx#next()
endfunction

"
" searchx#prev_dir
"
function searchx#prev_dir() abort
  if v:searchforward == 0
    return searchx#next()
  endif
  call searchx#prev()
endfunction

"
" searchx#prev
"
function! searchx#prev() abort
  if @/ !=# ''
    for l:i in range(1, s:state.prompt ? 1 : v:count1)
      let l:pos = searchpos(@/, 'wbn')
      if l:pos[0] != 0
        call s:goto(l:pos)
      endif
    endfor
    redraw
  endif
endfunction

"
" searchx#next
"
function! searchx#next() abort
  if @/ !=# ''
    for l:i in range(1, s:state.prompt ? 1 : v:count1)
      let l:pos = searchpos(@/, 'wzn')
      if l:pos[0] != 0
        call s:goto(l:pos)
      endif
    endfor
    redraw
  endif
endfunction

"
" searchx#redraw
"
function! searchx#redraw() abort
  call s:on_input({ 'is_userinput': v:false })
endfunction

"
" s:goto
"
function! s:goto(pos) abort
  call searchx#cursor#goto(a:pos)
  if s:state.prompt
    let s:state.matches = s:find_matches(@/, a:pos)
    call s:refresh({ 'marker': g:searchx.auto_accept, 'incsearch': v:true })
  elseif reg_executing() ==# ''
    let s:state.matches = s:find_matches(@/, a:pos)
    call searchx#async#step([
    \   { next -> [s:refresh({ 'marker': v:false, 'incsearch': v:true }), searchx#async#timeout('goto', 500, next)] },
    \   { next -> [s:refresh({ 'marker': v:false, 'incsearch': v:false }), next()] },
    \   { next -> [searchx#searchundo#hlsearch(v:true), next()] },
    \ ] + (g:searchx.nohlsearch.jump ? [
    \   { next -> [s:auto_nohlsearch(), next()] },
    \ ] : []))
  endif
endfunction

"
" s:auto_nohlsearch
"
function! s:auto_nohlsearch() abort
  augroup searchx-auto-nohlsearch
    autocmd!
    autocmd CursorMoved *
          \ autocmd searchx-auto-nohlsearch CursorMoved * ++once
          \ call searchx#searchundo#hlsearch(v:false)
          \ | autocmd! searchx-auto-nohlsearch
  augroup END
endfunction

"
" s:accept_marker
"
function! s:accept_marker(match) abort
  let s:state.accept_reason = s:AcceptReason.Marker
  call searchx#cursor#goto([a:match.lnum, a:match.col])
  if s:state.prompt
    " Remove marker input.
    call feedkeys("\<BS>\<CR>", 'n')
  else
    call s:clear()
  endif
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
function! s:on_input(...) abort
  let l:option = get(a:000, 0, {})
  let l:option.is_userinput = get(l:option, 'is_userinput', v:true)

  try
    " Check marker.
    let l:input = getcmdline()
    if g:searchx.auto_accept && strlen(l:input) > 0
      let l:index = index(g:searchx.markers, l:input[strlen(l:input) - 1])
      if l:index >= 0
        for l:match in s:state.matches.matches
          if l:match.marker ==# g:searchx.markers[l:index]
            return s:accept_marker(l:match)
          endif
        endfor
      endif
    endif

    " Check prompt emptiness
    if strlen(l:input) == 0
      if s:state.prompt_emptily && l:option.is_userinput
        call feedkeys(" \<BS>", 'n')
      else
        let s:state.prompt_emptily = v:true
      endif
      return
    else
      let s:state.prompt_emptily = v:false
    endif

    let l:input = s:state.convert(l:input)
    if @/ ==# l:input
      return
    endif

    " Check backspace.
    if stridx(l:input, @/) != 0
      silent noautocmd call winrestview(s:state.firstview)
    endif

    " Update search pattern.
    let @/ = l:input
    call searchx#searchundo#searchforward(s:state.direction)


    " Update view state.
    let s:state.matches = s:find_matches(@/, getcurpos()[1:2])
    call s:refresh({ 'marker': g:searchx.auto_accept })

    " Search off-screen match.
    if empty(s:state.matches.matches)
      silent noautocmd call winrestview(s:state.firstview)
      let l:next_pos = searchpos(@/, s:state.direction == s:Direction.Next ? 'zn' : 'bn')
      if l:next_pos[0] == 0
      endif
      call searchx#next_dir()
    " Move to current match.
    "
    else
      if s:state.matches.current isnot v:null
        call searchx#cursor#goto([s:state.matches.current.lnum, s:state.matches.current.col])
      endif
      redraw

    endif

    doautocmd <nomodeline> User SearchxInputChanged
  catch /^Vim\%((\a\+)\)\=:E54/
    " ignore
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
  call searchx#searchundo#hlsearch(len(s:state.matches.matches) > 0)
endfunction

"
" clear
"
function s:clear() abort
  call searchx#async#clear()
  call searchx#highlight#clear()
  call searchx#searchundo#hlsearch(v:false)
endfunction

"
" find_matches
"
function! s:find_matches(input, curpos) abort

  let l:lnum_start = line('w0')
  let l:lnum_s = a:curpos[0]
  let l:lnum_e = line('w$')

  if s:state.direction == 1
    let l:lnum_start = line('w0')
    let l:lnum_s = a:curpos[0]
    let l:lnum_e = line('w$')
    let l:texts = getbufline('%', l:lnum_s, l:lnum_e)
    let l:texts_wrap = getbufline('%',l:lnum_start,  a:curpos[0] - 1)
    call reverse(l:texts_wrap)
    let l:next = v:null
    let l:prev = v:null
    let l:matches = []

    " forward match from cursor to end of screen in chosen direction
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

        " nearest next.
        if empty(l:next) && (a:curpos[0] < l:match.lnum || a:curpos[0] == l:match.lnum && a:curpos[1] <= l:match.col)
          let l:next = l:match
        endif

        " nearest prev.
        if a:curpos[0] > l:match.lnum || a:curpos[0] == l:match.lnum && a:curpos[1] >= l:match.col
          let l:prev = l:match
        endif

        " add match.
        call add(l:matches, l:match)

        let l:off = l:match.end_col
      endwhile
    endfor


    " wrap match, from cursor to end of screen in opposite selected direction
    for l:i in range(0, len(l:texts_wrap) - 1)
      let l:text = l:texts_wrap[l:i]
      let l:off = 0
      while l:off < strlen(l:text)
        let l:m = matchstrpos(l:text, a:input, l:off, 1)
        if l:m[0] ==# ''
          break
        endif

        let l:match = {
        \   'id': len(l:matches) + 1,
        \   'lnum': l:lnum_s - l:i - 1,
        \   'col': l:m[1] + 1,
        \   'end_col': l:m[2] + 1,
        \   'marker': get(g:searchx.markers, len(l:matches), v:null),
        \   'current': v:false,
        \ }

        " nearest next.
        if empty(l:next) && (a:curpos[0] < l:match.lnum || a:curpos[0] == l:match.lnum && a:curpos[1] <= l:match.col)
          let l:next = l:match
        endif

        " nearest prev.
        if a:curpos[0] > l:match.lnum || a:curpos[0] == l:match.lnum && a:curpos[1] >= l:match.col
          let l:prev = l:match
        endif

        " add match.
        call add(l:matches, l:match)

        let l:off = l:match.end_col
      endwhile
    endfor

    " Select current match.
    let l:next = empty(l:next) ? l:prev : l:next
    let l:prev = empty(l:prev) ? l:next : l:prev
    let l:current = s:state.direction == s:Direction.Next ? l:next : l:prev
    if !empty(l:current)
      let l:current.current = v:true
    endif

  " reverse direction
  else

    let l:next = v:null
    let l:prev = v:null
    let l:matches = []

    let l:texts = getbufline('%', l:lnum_s + 1, l:lnum_e)
    let l:texts_wrap = getbufline('%',l:lnum_start,  a:curpos[0])
    call reverse(l:texts_wrap)

    " wrap match
    for l:i in range(0, len(l:texts_wrap) - 1)
      let l:text = l:texts_wrap[l:i]
      let l:off = 0
      while l:off < strlen(l:text)
        let l:m = matchstrpos(l:text, a:input, l:off, 1)
        if l:m[0] ==# ''
          break
        endif

        let l:match = {
        \   'id': len(l:matches) + 1,
        \   'lnum': l:lnum_s - l:i,
        \   'col': l:m[1] + 1,
        \   'end_col': l:m[2] + 1,
        \   'marker': get(g:searchx.markers, len(l:matches), v:null),
        \   'current': v:false,
        \ }

        " nearest next.
        if empty(l:next) && (a:curpos[0] > l:match.lnum || a:curpos[0] == l:match.lnum && a:curpos[1] >= l:match.col)
          let l:next = l:match
        endif

        " nearest prev.
        if a:curpos[0] < l:match.lnum || a:curpos[0] == l:match.lnum && a:curpos[1] <= l:match.col
          let l:prev = l:match
        endif

        " add match.
        call add(l:matches, l:match)

        let l:off = l:match.end_col
      endwhile
    endfor

    " Select current match.
    let l:next = empty(l:next) ? l:prev : l:next
    let l:prev = empty(l:prev) ? l:next : l:prev

    let l:current = l:next
    if !empty(l:current)
      let l:current.current = v:true
    endif

    " forward match
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
        \   'lnum': l:lnum_s + l:i + 1,
        \   'col': l:m[1] + 1,
        \   'end_col': l:m[2] + 1,
        \   'marker': get(g:searchx.markers, len(l:matches), v:null),
        \   'current': v:false,
        \ }

        " " add match.
        call add(l:matches, l:match)

        let l:off = l:match.end_col
      endwhile
    endfor
  endif


  return { 'matches': l:matches, 'current': l:current }
endfunction


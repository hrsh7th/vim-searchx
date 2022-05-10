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
  let l:scrolloff = g:searchx.scrolloff isnot v:null ? g:searchx.scrolloff : &scrolloff
  let l:above = line('w0') + l:scrolloff
  let l:below = line('w$') - l:scrolloff
  let l:dir = 0
  let l:steps = []
  if a:lnum < l:above
    let l:dir = 0
    let l:steps = repeat(["\<C-y>"], l:above - a:lnum)
  elseif l:below < a:lnum
    let l:dir = 1
    let l:steps = repeat(["\<C-e>"], a:lnum - l:below)
  endif

  if reg_executing() ==# ''
    let l:total_value = len(l:steps) - 1
    if l:scrolloff < l:total_value
      let l:saved_cursorline = &cursorline
      let l:saved_scrolloff = &scrolloff
      let l:saved_virtualedit = &virtualedit

      let &cursorline = v:false
      let &scrolloff = 0
      let &virtualedit = 'all'
      let l:prev_value = 0
      let l:start_time = reltimefloat(reltime()) * 1000
      let l:curr_time = l:start_time
      let l:total_time = l:start_time + g:searchx.scrolltime
      while l:curr_time < l:total_time
        let l:curr_time = reltimefloat(reltime()) * 1000
        let l:next_value = s:easing(l:start_time, l:curr_time, l:total_time, l:total_value)
        for l:i in range(l:prev_value, l:next_value)
          execute printf('normal! %s', l:steps[l:i])
        endfor
        let l:prev_value = l:next_value + 1

        if l:dir == 0
          call cursor(line('w0') + l:scrolloff - 1, a:col)
        else
          call cursor(line('w$') - l:scrolloff + 1, a:col)
        endif
        redraw
        sleep 16ms
      endwhile
      let &cursorline = l:saved_cursorline
      let &scrolloff = l:saved_scrolloff
      let &virtualedit = l:saved_virtualedit
    endif
  endif

  call cursor(a:lnum, a:col)
endfunction

function! s:easing(start_time, curr_time, total_time, total_value) abort
  return min([a:total_value, float2nr(a:total_value * (-pow(2, -10 * ((a:curr_time - a:start_time) / (a:total_time - a:start_time)) ) + 1))])
endfunction


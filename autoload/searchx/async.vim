let s:timers = {}

"
" searchx#async#timeout
"
function! searchx#async#timeout(name, timeout, func) abort
  let l:timer = get(s:timers, a:name, 0)
  call timer_stop(l:timer)
  let s:timers[a:name] = timer_start(a:timeout, a:func)
endfunction

"
" searchx#async#step
"
function! searchx#async#step(steps) abort
  let l:steps = copy(a:steps)
  function! s:next() abort closure
    if len(l:steps) == 0
      return
    endif
    call remove(l:steps, 0)({ -> s:next() })
  endfunction
  call s:next()
endfunction

"
" searchx#async#clear
"
function! searchx#async#clear() abort
  for [l:k, l:v] in items(s:timers)
    call timer_stop(l:v)
  endfor
endfunction


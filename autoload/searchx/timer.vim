let s:timers = {}

"
" searchx#timer#start
"
function! searchx#timer#start(name, timeout, func) abort
  let l:timer = get(s:timers, a:name, 0)
  call timer_stop(l:timer)
  let s:timers[a:name] = timer_start(a:timeout, a:func)
endfunction

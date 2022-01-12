let s:state = {}
let s:state.hlsearch = v:false
let s:state.searchforward = 1
let s:state.running = v:false

"
" searchx#searchundo#hlsearch
"
function! searchx#searchundo#hlsearch(v) abort
  let v:hlsearch = a:v
  let s:state.hlsearch = a:v
  call s:update()
endfunction

"
" searchx#searchundo#searchforward
"
function! searchx#searchundo#searchforward(v) abort
  let v:searchforward = a:v
  let s:state.searchforward = a:v
  call s:update()
endfunction

"
" _state
"
function! searchx#searchundo#_state(...) abort
  let l:merge = get(a:000, 0, {})
  let s:state = extend(l:merge, s:state, 'keep')
  return s:state
endfunction

"
" update
"
function! s:update() abort
  if !s:state.running
    let s:state.running = v:true
    call feedkeys("\<Cmd>call searchx#searchundo#_state({ 'running': v:false })\<CR>", 'ni')
    call feedkeys("\<Cmd>let v:searchforward = searchx#searchundo#_state().searchforward\<CR>", 'ni')
    call feedkeys("\<Cmd>let v:hlsearch = searchx#searchundo#_state().hlsearch\<CR>", 'ni')
  endif
endfunction


let s:state = {}
let s:state.hlsearch = v:false
let s:state.running = v:false

"
" searchx#hlsearch#set
"
function! searchx#hlsearch#set(bool) abort
  let s:state.hlsearch = a:bool
  if !s:state.running
    let s:state.running = v:true
    call feedkeys("\<Cmd>let v:hlsearch = searchx#hlsearch#get()\<CR>", 'n')
    call feedkeys("\<Cmd>call searchx#hlsearch#_done()\<CR>", 'n')
  endif
endfunction

"
" searchx#hlsearch#get
"
function! searchx#hlsearch#get() abort
  return s:state.hlsearch
endfunction

"
" searchx#hlsearch#_done
"
function! searchx#hlsearch#_done() abort
  let s:state.running = v:false
endfunction


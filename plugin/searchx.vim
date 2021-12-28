if exists('g:loaded_searchx')
  finish
endif
let g:loaded_searchx = v:true

let g:searchx = get(g:, 'searchx', {})
let g:searchx.markers = get(g:searchx, 'markers', split('ABCDEFGHIJKLMNOPQRSTUVWXYZ', '.\zs'))

if !hlexists('SearchxSearch')
  highlight default link SearchxSearch Search
endif

if !hlexists('SearchxIncSearch')
  highlight default link SearchxIncSearch IncSearch
endif

if !hlexists('SearchxMarker')
  highlight default link SearchxMarker VisualNOS
endif

nnoremap / <Cmd>call searchx#run(1)<CR>
nnoremap ? <Cmd>call searchx#run(0)<CR>
cnoremap <C-j> <Cmd>call searchx#next()<CR>
cnoremap <C-k> <Cmd>call searchx#prev()<CR>
nnoremap n <Cmd>call searchx#next()<CR>
nnoremap N <Cmd>call searchx#prev()<CR>


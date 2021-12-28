if exists('g:loaded_searchx')
  finish
endif
let g:loaded_searchx = v:true

let g:searchx = get(g:, 'searchx', {})
let g:searchx.fuzzy = get(g:searchx, 'fuzzy', v:true)
let g:searchx.markers = get(g:searchx, 'markers', split('ABCDEFGHIJKLMNOPQRSTUVWXYZ', '.\zs'))
let g:searchx.convert = get(g:searchx, 'convert', { input -> input })

if !hlexists('SearchxIncSearch')
  highlight default link SearchxIncSearch IncSearch
endif

if !hlexists('SearchxMarker')
  highlight default link SearchxMarker VisualNOS
endif


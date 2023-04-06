if exists('g:loaded_searchx')
  finish
endif
let g:loaded_searchx = v:true

let g:searchx = get(g:, 'searchx', {})
let g:searchx.auto_accept = get(g:searchx, 'auto_accept', v:false)
let g:searchx.markers = get(g:searchx, 'markers', split('ABCDEFGHIJKLMNOPQRSTUVWXYZ', '.\zs'))
let g:searchx.convert = get(g:searchx, 'convert', { input -> input })
let g:searchx.scrolloff = get(g:searchx, 'scrolloff', v:null)
let g:searchx.scrolltime = get(g:searchx, 'scrolltime', 0)
let g:searchx.nohlsearch = get(g:searchx, 'nohlsearch', {'jump': v:false})
let g:searchx.save_state_when = get(g:searchx, 'save_state_when', 'accept')

augroup searchx-silent
  autocmd User SearchxEnter silent
  autocmd User SearchxLeave silent
  autocmd User SearchxInputChanged silent
  autocmd User SearchxCancel silent
  autocmd User SearchxAccept silent
  autocmd User SearchxAcceptReturn silent
  autocmd User SearchxAcceptMarker silent
  autocmd User SearchxCancel silent
augroup END

if !hlexists('SearchxIncSearch')
  highlight default link SearchxIncSearch IncSearch
endif

if !hlexists('SearchxMarker')
  highlight default link SearchxMarker DiffAdd
endif

if !hlexists('SearchxMarkerCurrent')
  highlight default link SearchxMarkerCurrent DiffText
endif


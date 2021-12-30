let s:incsearch_id = 0

"
" set_incsearch
"
function! searchx#highlight#set_incsearch(match) abort
  let s:incsearch_id = matchaddpos('SearchxIncSearch', [[a:match.lnum, a:match.col, a:match.end_col - a:match.col]])
endfunction

"
" add_marker
"
function! searchx#highlight#add_marker(match) abort
  call s:add_marker(a:match)
endfunction

"
" clear
"
function! searchx#highlight#clear() abort
  try
    silent! call matchdelete(s:incsearch_id)
  catch /.*/
  endtry
  call s:clear_marker()
endfunction

"
" add_marker/clear_marker
"
if has('nvim')
  let s:marker_ns  = nvim_create_namespace('searchx:marker')

  "
  " add_marker
  "
  function! s:add_marker(match) abort
    if !empty(a:match.marker)
      call nvim_buf_set_extmark(0, s:marker_ns, a:match.lnum - 1, max([0, a:match.col - 2]), {
      \   'id': a:match.id,
      \   'end_line': a:match.lnum - 1,
      \   'end_col': max([0, a:match.col - 2]),
      \   'virt_text': [[a:match.marker, (a:match.current ? 'SearchxMarkerCurrent' : 'SearchxMarker')]],
      \   'virt_text_pos': 'overlay',
      \   'priority': 1000,
      \ })
    endif
  endfunction

  "
  " clear_marker
  "
  function! s:clear_marker() abort
    call nvim_buf_clear_namespace(0, s:marker_ns, 0, -1)
  endfunction
else
  call prop_type_delete('searchx_marker', {})
  call prop_type_add('searchx_marker', {})

  "
  " add_marker
  "
  function! s:add_marker(match) abort
    if !empty(a:match.marker)
      call prop_add(a:match.lnum, a:match.col, {
      \   'type': 'searchx_marker',
      \   'id': a:match.id,
      \ })
      call popup_create(a:match.marker, {
      \   'line': -1,
      \   'col': -1,
      \   'textprop': 'searchx_marker',
      \   'textpropid': a:match.id,
      \   'width': 1,
      \   'height': 1,
      \   'highlight': 'SearchxMarker'
      \ })
    endif
  endfunction

  "
  " clear_marker
  "
  function! s:clear_marker() abort
    call prop_remove({ 'type': 'searchx_marker' })
  endfunction
endif


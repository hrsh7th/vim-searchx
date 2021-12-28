if has('nvim')
  let s:marker_ns  = nvim_create_namespace('searchx:marker')

  "
  " marker
  "
  function! searchx#highlight#marker(match) abort
    if !empty(a:match.marker)
      call nvim_buf_set_extmark(0, s:marker_ns, a:match.lnum - 1, max([0, a:match.col - 2]), {
      \   'id': a:match.id,
      \   'end_line': a:match.lnum - 1,
      \   'end_col': max([0, a:match.col - 2]),
      \   'virt_text': [[a:match.marker, 'SearchxMarker']],
      \   'virt_text_pos': 'overlay',
      \   'priority': 1000,
      \ })
    endif
  endfunction

  "
  " remove
  "
  function! searchx#highlight#remove(match) abort
    call s:remove_incsearch()
    call nvim_buf_del_extmark(0, s:marker_ns, a:match.id)
  endfunction
else
  call prop_type_delete('searchx_marker', {})
  call prop_type_add('searchx_marker', {})

  "
  " incsearch
  "
  function! searchx#highlight#incsearch(match) abort
    call prop_add(a:match.lnum, a:match.col, {
    \   'type': 'searchx_incsearch',
    \   'id': a:match.id,
    \   'end_lnum': a:match.lnum,
    \   'end_col': a:match.end_col,
    \ })
  endfunction

  "
  " marker
  "
  function! searchx#highlight#marker(match) abort
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
  " remove
  "
  function! searchx#highlight#remove(match) abort
    call s:remove_incsearch()
    call prop_remove({ 'both': v:true, 'type': 'searchx_marker', 'id': a:match.id })
  endfunction
endif


  let s:incsearch_id = 0
  "
  " incsearch
  "
  function! searchx#highlight#incsearch(match) abort
    let s:incsearch_id = matchaddpos('SearchxIncSearch', [[a:match.lnum, a:match.col, a:match.end_col - a:match.col]])
  endfunction

  "
  " remove_incsearch
  "
  function! s:remove_incsearch() abort
    try
      silent! call matchdelete(s:incsearch_id)
    catch /.*/
    endtry
  endfunction

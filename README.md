A plugin that improves experimental /.

I've written a lot of similar plugins and thrown them away.

I don't know if to maintain this.

```vim
nnoremap / <Cmd>call searchx#run(1)<CR>
nnoremap ? <Cmd>call searchx#run(0)<CR>
xnoremap / <Cmd>call searchx#run(1)<CR>
xnoremap ? <Cmd>call searchx#run(0)<CR>

nnoremap n <Cmd>call searchx#search_next()<CR>
nnoremap N <Cmd>call searchx#search_prev()<CR>
xnoremap n <Cmd>call searchx#search_next()<CR>
xnoremap N <Cmd>call searchx#search_prev()<CR>

cnoremap <C-j> <Cmd>call searchx#search_next()<CR>
cnoremap <C-k> <Cmd>call searchx#search_prev()<CR>

nnoremap <C-l> <Cmd>call searchx#clear()<CR>

let g:searchx = {}

"
" You can customize markers.
"
let g:searchx.markers = split('asdfghjkl;', '.\zs')

"
" You can customize regex pattern via `g:searchx.convert`.
"
function g:searchx.convert(input) abort
  let l:input = a:input

  " <Space> as fuzzy match separator.
  let l:input = join(split(l:input, ' '), '.\{-}')

  " / as word-end identifier.
  if l:input[strlen(l:input) - 1] ==# '/'
    let l:input = l:input[0 : strlen(l:input) - 2] .. '\k*\zs.'
  endif

  " symbol only input as literal pattern.
  if l:input !~# '\k'
    let l:input = '\V' .. l:input
  endif

  return l:input
endfunction
```


### Similar plugins

- [vim-seak](https://github.com/hrsh7th/vim-seak)
- [vim-foolish-move](https://github.com/hrsh7th/vim-foolish-move)
- [vim-feeling-move](https://github.com/hrsh7th/vim-feeling-move)
- [vim-aim](https://github.com/hrsh7th/vim-aim)
- [vim-insert-point](https://github.com/hrsh7th/vim-insert-point)


# vim-searchx

The extended search motion.

- Jump to the specific match via marker (like easymotion)
- Move cursor during searching
- Input converter
- Improved jumplist management


### Settings

```vim
" Overwrite / and ?.
nnoremap ? <Cmd>call searchx#run(0)<CR>
nnoremap / <Cmd>call searchx#run(1)<CR>
xnoremap ? <Cmd>call searchx#run(0)<CR>
xnoremap / <Cmd>call searchx#run(1)<CR>

" Move to next/prev match.
nnoremap N <Cmd>call searchx#search_prev()<CR>
nnoremap n <Cmd>call searchx#search_next()<CR>
xnoremap N <Cmd>call searchx#search_prev()<CR>
xnoremap n <Cmd>call searchx#search_next()<CR>
nnoremap <C-k> <Cmd>call searchx#search_prev()<CR>
nnoremap <C-j> <Cmd>call searchx#search_next()<CR>
xnoremap <C-k> <Cmd>call searchx#search_prev()<CR>
xnoremap <C-j> <Cmd>call searchx#search_next()<CR>
cnoremap <C-k> <Cmd>call searchx#search_prev()<CR>
cnoremap <C-j> <Cmd>call searchx#search_next()<CR>

" Clear highlights
nnoremap <C-l> <Cmd>call searchx#clear()<CR>

" Customize behaviors.
let g:searchx = {}
let g:searchx.markers = split('asdfhjkl;', '.\zs')
function g:searchx.convert(input) abort
  if a:input !~# '\k'
    return '\V' .. a:input
  endif
  let l:sep = a:input[0] =~# '[[:alnum:]]' ? '[^[:alnum:]]\zs' : '[[:alnum:]]\zs'
  return l:sep .. join(split(a:input, ' '), '.\{-}')
endfunction
```


### Side note

I was develop similar plugins before for experimenting and thrown them away.

I don't know if to maintein it, but this plugin is more convenient than the followings.

- [vim-seak](https://github.com/hrsh7th/vim-seak)
- [vim-foolish-move](https://github.com/hrsh7th/vim-foolish-move)
- [vim-feeling-move](https://github.com/hrsh7th/vim-feeling-move)
- [vim-aim](https://github.com/hrsh7th/vim-aim)
- [vim-insert-point](https://github.com/hrsh7th/vim-insert-point)


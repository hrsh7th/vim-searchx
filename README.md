# vim-searchx

The extended search motion.

- Jump to the specific match via marker (like easymotion)
- Move cursor during searching
- Input converter
- Improved jumplist management


### Settings

```vim
" Overwrite / and ?.
nnoremap ? <Cmd>call searchx#start({ 'dir': 0 })<CR>
nnoremap / <Cmd>call searchx#start({ 'dir': 1 })<CR>
xnoremap ? <Cmd>call searchx#start({ 'dir': 0 })<CR>
xnoremap / <Cmd>call searchx#start({ 'dir': 1 })<CR>
cnoremap ; <Cmd>call searchx#select()<CR>

" Move to next/prev match.
nnoremap N <Cmd>call searchx#prev_dir()<CR>
nnoremap n <Cmd>call searchx#next_dir()<CR>
xnoremap N <Cmd>call searchx#prev_dir()<CR>
xnoremap n <Cmd>call searchx#next_dir()<CR>
nnoremap <C-k> <Cmd>call searchx#prev()<CR>
nnoremap <C-j> <Cmd>call searchx#next()<CR>
xnoremap <C-k> <Cmd>call searchx#prev()<CR>
xnoremap <C-j> <Cmd>call searchx#next()<CR>
cnoremap <C-k> <Cmd>call searchx#prev()<CR>
cnoremap <C-j> <Cmd>call searchx#next()<CR>

" Clear highlights
nnoremap <C-l> <Cmd>call searchx#clear()<CR>

let g:searchx = {}

" Auto jump if the recent input matches to any marker.
let g:searchx.auto_accept = v:true

" Marker characters.
let g:searchx.markers = split('ABCDEFGHIJKLMNOPQRSTUVWXYZ', '.\zs')

" Convert search pattern.
function g:searchx.convert(input) abort
  if a:input !~# '\k'
    return '\V' .. a:input
  endif
  return join(split(a:input, ' '), '.\{-}')
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


A plugin that improves experimental /.

I've written a lot of similar plugins and thrown them away.

I don't know if to maintain this.

```vim
nnoremap / <Cmd>call searchx#run(1)<CR>
nnoremap ? <Cmd>call searchx#run(0)<CR>
nnoremap n <Cmd>call searchx#next()<CR>
nnoremap N <Cmd>call searchx#prev()<CR>
cnoremap <C-j> <Cmd>call searchx#next()<CR>
cnoremap <C-k> <Cmd>call searchx#prev()<CR>
```


### similar plugins

- [vim-seak](https://github.com/hrsh7th/vim-seak)
- [vim-foolish-move](https://github.com/hrsh7th/vim-foolish-move)
- [vim-feeling-move](https://github.com/hrsh7th/vim-feeling-move)
- [vim-aim](https://github.com/hrsh7th/vim-aim)
- [vim-insert-point](https://github.com/hrsh7th/vim-aim)

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



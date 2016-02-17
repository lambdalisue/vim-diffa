nnoremap <silent><expr> <Plug>(diffa-C-l) &diff
      \ ? ':<C-u>diffupdate<CR><C-l>'
      \ : '<C-l>'
nnoremap <silent> <Plug>(diffa-enable)   :<C-u>call diffa#enable()<CR>
nnoremap <silent> <Plug>(diffa-disable)  :<C-u>call diffa#disable()<CR>
nnoremap <silent> <Plug>(diffa-difforig) :<C-u>call diffa#difforig()<CR>

if get(g:, 'diffa_enable', 1)
  call diffa#enable()
endif
if get(g:, 'diffa_enable_diffexpr', 1)
  if diffa#unified#is_available()
    set diffexpr=diffa#unified#diffexpr()
  endif
endif
if get(g:, 'diffa_enable_DiffOrig', 1)
  command! DiffOrig call diffa#difforig()
endif

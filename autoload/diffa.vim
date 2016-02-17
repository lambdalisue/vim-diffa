let s:V = vital#of('diffa')

function! s:on_BufEnter() abort
  if !exists('t:_diffa_on_BufLeave')
    return
  endif
  try
    let info = t:_diffa_on_BufLeave
    if info.nwin == 0 || info.nwin <= winnr('$')
      return
    endif
    if info.bufnum == 0
      return
    endif
    if bufloaded(info.bufnum)
      for winnum in range(tabpagenr())
        if winbufnr(winnum) == info.bufnum && getwinvar(winnum, '&diff')
          " cancel operation while there is a window which show the buffer and
          " is in diff mode
          return
        endif
      endfor
    endif
    " NOTE: &diff is window local but there is no window so use setbufvar
    " while it works fine.
    call setbufvar(info.bufnum, '&diff', 0)
  finally
    silent! unlet t:_diffa_on_BufLeave
  endtry
endfunction
function! s:on_BufLeave() abort
  if &diff
    let t:_diffa_on_BufLeave = {}
    let t:_diffa_on_BufLeave.nwin = winnr('$')
    let t:_diffa_on_BufLeave.bufnum = bufnr('%')
  else
    silent! unlet t:_diffa_on_BufLeave
  endif
endfunction

function! diffa#vital() abort
  return s:V
endfunction

function! diffa#enable() abort
  augroup vim_diffa
    autocmd! *
    if g:diffa#enable_auto_diffupdate
      autocmd InsertLeave * if &diff | diffupdate | endif
    endif
    if g:diffa#enable_auto_diffoff
      autocmd BufEnter * call s:on_BufEnter()
      autocmd BufLeave * call s:on_BufLeave()
    endif
  augroup END
endfunction

function! diffa#disable() abort
  augroup vim_diffa
    autocmd! *
  augroup END
endfunction

function! diffa#difforig() abort
  let ftype = &filetype
  let fname = expand('%')
  let bufnum = bufnr('%')
  noautocmd execute printf('keepjumps new ORIG:%s', fname)
  keepjumps r # | keepjumps normal! 1Gdd
  execute printf('filetype %s', ftype)
  setlocal buftype=nofile noswapfile nobuflisted bufhidden=wipe
  setlocal nomodifiable
  call diffa#diffthis()
  execute printf('%swincmd w', bufwinnr(bufnum))
  call diffa#diffthis()
endfunction

function! diffa#define_variables(prefix, defaults) abort
  " Note:
  "   Funcref is not supported while the variable must start with a capital
  let prefix = empty(a:prefix)
        \ ? 'g:diffa'
        \ : printf('g:diffa#%s', a:prefix)
  for [key, value] in items(a:defaults)
    let name = printf('%s#%s', prefix, key)
    if !exists(name)
      execute printf('let %s = %s', name, string(value))
    endif
    unlet value
  endfor
endfunction

call diffa#define_variables('', {
      \ 'enable_auto_diffupdate': 1,
      \ 'enable_auto_diffoff': 1,
      \})

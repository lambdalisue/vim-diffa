let s:V = vital#of('diffa')
let s:Prelude = s:V.import('Prelude')
let s:Python = s:V.import('Vim.Python')
let s:Path = s:V.import('System.Filepath')
let s:Process = s:V.import('Process')

let s:script_root = expand('<sfile>:p:h')
let s:region_pattern =
      \ '^@@ -\(\d\+\)\%(,\(\d\+\)\)\? +\(\d\+\)\%(,\(\d\+\)\)\? @@'

function! s:parse_unified_region(line) abort
  let m = matchlist(a:line, s:region_pattern)
  if empty(m)
    throw printf('diffa: An invalid format line "%s" was found.', a:line)
  endif
  let m = m[1 : 4]
  " find correct action
  if m[1] ==# '0'
    let a = 'a'
  elseif m[3] ==# '0'
    let a = 'd'
  else
    let a = 'c'
  endif
  " find correct endpoint
  let send = ''
  if !empty(m[1]) && m[1] !=# '0'
    let send = ',' . (m[0] + m[1] - 1)
  endif
  let dend = ''
  if !empty(m[3]) && m[3] !=# '0'
    let dend = ',' . (m[2] + m[3] - 1)
  endif
  return join([m[0], send, a, m[2], dend], '')
endfunction

function! s:parse_unified(unified) abort
  let _normal = []
  for line in a:unified
    if line =~# '^\%(+++\|---\)'
      continue
    elseif line =~# s:region_pattern
      call add(_normal, s:parse_unified_region(line))
    elseif line =~# '^-'
      call add(_normal, substitute(line, '^-', '< ', ''))
    elseif line =~# '^+'
      if _normal[-1] =~# '\v^\< '
        call add(_normal, '---')
      endif
      call add(_normal, substitute(line, '^+', '> ', ''))
    endif
  endfor
  return _normal
endfunction

function! s:parse_unified_python(unified, options) abort
  let python = a:options.python == 1 ? 0 : a:options.python
  execute s:Python.exec_file(s:Path.join(s:script_root, 'unified.py'), python)
  " NOTE:
  " To support neovim, bindeval cannot be used for now.
  " That's why eval_expr is required to call separatly
  let response = s:Python.eval_expr(
        \ '_vim_diffa_unified_parse_unified_result'
        \)
  let prefix = '_vim_diffa_unified'
  let code = [
        \ printf('del %s_parse_unified', prefix),
        \ printf('del %s_parse_unified_result', prefix),
        \ printf('del %s_format_exception', prefix),
        \]
  execute s:Python.exec_code(code, python)
  if s:Prelude.is_string(response)
    throw 'diffa: ' . response
  endif
  return response
endfunction

function! diffa#unified#parse(unified, ...) abort
  let options = extend({
        \ 'python': s:Python.is_enabled(),
        \}, get(a:000, 0, {}))
  return options.python
        \ ? s:parse_unified_python(a:unified, options)
        \ : s:parse_unified(a:unified)
endfunction

function! diffa#unified#diff(fname_in, fname_new) abort
  let args = [g:diffa#unified#executable] + g:diffa#unified#arguments
  if &diffopt =~# 'iwhite'
    call extend(args, g:diffa#unified#iwhite_arguments)
  endif
  call extend(args, [a:fname_in, a:fname_new])
  let unified = s:Process.system(args)
  let unified = substitute(unified, '\r\?\n$', '', '')
  return diffa#unified#parse(split(unified, '\r\?\n', 1))
endfunction

function! diffa#unified#diffexpr() abort
  let diff = diffa#unified#diff(v:fname_in, v:fname_new)
  call writefile(diff, v:fname_out)
endfunction

function! diffa#unified#is_available() abort
  return executable(g:diffa#unified#executable)
endfunction

call diffa#define_variables('unified', {
      \ 'executable': 'git',
      \ 'arguments': [
      \   'diff', '--no-index', '--histogram',
      \   '--no-color', '--no-ext-diff', '--unified=0',
      \ ],
      \ 'iwhite_arguments': [
      \   '--ignore-all-space',
      \ ],
      \})

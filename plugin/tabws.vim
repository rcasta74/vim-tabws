"
" MIT License

" Permission is hereby granted, free of charge, to any person obtaining
" a copy of this software and associated documentation files (the
" "Software"), to deal in the Software without restriction, including
" without limitation the rights to use, copy, modify, merge, publish,
" distribute, sublicense, and/or sell copies of the Software, and to
" permit persons to whom the Software is furnished to do so, subject to
" the following conditions:
"
" The above copyright notice and this permission notice shall be
" included in all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
" EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
" MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
" NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
" LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
" OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
" WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

if exists('g:tabws_loaded')
  finish
endif

let s:tabws_vimenterdone = 0

augroup TabWS
  autocmd! TabNew * call s:tabws_tabnew()
  autocmd! TabEnter * call s:tabws_tabenter()
  autocmd! TabLeave * call s:tabws_tableave()
  if exists("#TabNewEntered")
    autocmd! TabNewEntered * call s:tabws_tabnewentered()
  endif
  autocmd! TabClosed * call s:tabws_tabclosed(expand('<afile>'))
  autocmd! BufEnter * call s:tabws_bufenter()
  autocmd! BufCreate * call s:tabws_bufcreate()
  autocmd! BufAdd * call s:tabws_bufadd(expand('<afile>'))
  autocmd! BufNew * call s:tabws_bufnew(expand('<afile>'))
  autocmd! VimEnter * call s:tabws_vimenter()
augroup END

command! -nargs=1 TabWSSetName call tabws#settabname(<q-args>)
command! TabWSBufferList call <SID>tabws_bufferlist()
command! -nargs=1 -complete=customlist,<SID>tabws_buffernamecomplete TabWSJumpToBuffer call tabws#jumptobufferintab(<q-args>)
command! -nargs=* -complete=file TabWSEdit call <SID>tabws_edit(<q-args>)

if exists(':Alias')
  :Alias buffers TabWSBufferList
  :Alias ls TabWSBufferList
  :Alias buffer TabWSJumpToBuffer
  :Alias -range b TabWSJumpToBuffer
  :Alias tabe TabWSEdit
  :Alias tabed TabWSEdit
  :Alias tabedi TabWSEdit
  :Alias tabedit TabWSEdit
endif

if exists("*fzf#run")
  let g:fzf_buffer_function = 'tabws#getbuffers'
endif

function! s:tabws_edit(...)
  for fname in a:000
    let fname = fnameescape(fname)
    exec ":badd" fname
  endfor
endfunction

function! s:tabws_buffernamecomplete(ArgLead, CmdLine, CursorPos)
  let buffers = tabws#getbuffers()
  let buffernames = []
  for buffer in buffers
    call add(buffernames, fnamemodify(bufname(buffer), ":p:~:."))
  endfor
  return buffernames
endfunction


function! s:tabws_bufferlist()
  let buffers = tabws#getbuffers()
  let output = ''
  for buffer in buffers
    let mode = ''
    if buffer == bufnr("%")
      let mode = '%'
    elseif buffer == bufnr('#')
      let mode = '#'
    endif
    if bufwinnr(buffer) != -1
      let mode .= "a"
    elseif bufloaded(buffer)
      let mode .= "h"
    endif
    let modified = ''
    if getbufvar(buffer, '&modified')
      let modified = '+'
    endif
    let line = 'line 0'
    if bufloaded(buffer)
      let line = 'line ' . trim(execute("let buf=bufnr('%') | exec '" . buffer . "bufdo echo '''' . line(''.'')' | exec 'b' buf"))
    endif
    let name = ' "' . fnamemodify(bufname(buffer), ":p:~:.") . '"'
    let outputline = printf("%3s%3s%2s%2s", buffer, mode, modified, name)
    let outputline .= s:prepad(line, 45 - len(outputline), ' ')
    let output .= outputline . "\n"
  endfor
  echon output
endfunction


function! s:tabws_tabnew()
  "echom "TabNew " . tabpagenr()
endfunction

function! s:tabws_tabenter()
  "echom "TabEnter"
  call tabws#switchtotab(tabpagenr())
  call tabws#refreshtabline()
endfunction

function! s:tabws_tableave()
  "echom "TabLeave"
  call tabws#savetagstack()
  call tabws#setcurrentbufferfortab(tabpagenr(), bufnr('%'))
endfunction

function! s:tabws_tabnewentered()
  "echom "TabNewEntered " . tabpagenr()
  call tabws#setup_tab(tabpagenr())
  call tabws#switchtotab(tabpagenr())
endfunction

function! s:tabws_tabclosed(tabnum)
  "echom "TabClosed " . a:tabnum
  call tabws#deletedirectoryentryfortab(a:tabnum)
endfunction

function! s:tabws_bufenter()
  "echom "BufEnter " . bufnr('%')
  "call tabws#associatebufferwithtab(tabpagenr(), tabws#getcurrentbuffer(tabpagenr()))
  if s:tabws_vimenterdone == 1
    let tab =  tabws#setup_buffer(bufnr('%'))
    if tab != -1
      call tabws#jumptotab(tab)
      call tabws#switchtotab(tab)
    endif
  endif
endfunction

function! s:tabws_bufcreate()
  "echom "BufCreate " . tabpagenr() . " " . bufname(tabws#getcurrentbuffer(tabpagenr()))
endfunction

function! s:tabws_bufadd(bufnum)
  "echom "BufAdd " . tabpagenr() . " " . bufnr(a:bufnum) . " " . bufname(a:bufnum)
  call tabws#setup_buffer(bufnr(a:bufnum))
endfunction

function! s:tabws_bufnew(bufnum)
  "echom "BufNew " . tabpagenr() . " " . bufnr(a:bufnum) . " " . bufname(a:bufnum)
endfunction

function! s:tabws_vimenter()
  "echom "VimEnter " . tabpagenr(). ': ' . bufnr('$')

  if bufnr('$') >= 1
    call tabws#associatebufferwithtab(tabpagenr(), 1)
    call tabws#setup_tab(tabpagenr())
    call tabws#setcurrentbufferfortab(tabpagenr(), bufnr('%'))
  endif

  for buffer in range(2,bufnr('$'))
    call tabws#setup_buffer(buffer)
  endfor
  exec ":1tabn"
  let s:tabws_vimenterdone = 1
  call tabws#switchtotab(1)
endfunction
let g:tabws_loaded = 1

function! s:prepad(s,amt,...)
  if a:0 > 0
    let char = a:1
  else
    let char = ' '
  endif
  return repeat(char,a:amt - len(a:s)) . a:s
endfunction

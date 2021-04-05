let s:src_field = 'f5src'
let s:term_field = 'f5term'

let s:default_pos = 'right'
let s:postions = {
            \ 'left': {'vert': 1, 'rb': 0},
            \ 'right': {'vert': 1, 'rb': 1},
            \ 'top': {'vert': 0, 'rb': 0},
            \ 'bottom': {'vert': 0, 'rb': 1}
            \}

let s:cmds = {
            \ 'c': 'gcc % -g -o %< && ./%<',
            \ 'cpp': 'g++ % -std=c++11 -g -o %< && ./%<',
            \ 'python': 'python %',
            \ 'perl': 'perl %',
            \ 'sh': 'sh %',
            \ 'go': 'go run %',
            \ 'cs': 'csc % && mono ./%<.exe',
            \ 'javascript': 'node %',
            \ 'haskell': 'runhaskell %'
            \}

let g:f5#pos = get(g:, 'f5#pos', s:default_pos)

func! s:GetCommand(filetype)
    return expandcmd(get(s:cmds, a:filetype, ''))
endfunc

func! s:GetPosInfo()
    return get(s:postions, g:f5#pos, get(s:postions, s:default_pos))
endfunc

func! s:TermStart(cmd, curwin, vert)
    call term_start(['bash', '-c', a:cmd],
                \ {'term_name': "F5: " . a:cmd,
                \ 'vertical': a:vert,
                \ 'curwin': a:curwin})
endfunc

func! s:RunInShell(cmd)
    let curwin = 0
    let srcbuf = bufnr('%')
    let srcwin = win_getid()
    let srcinfo = getbufvar(srcbuf, s:src_field, {})
    if len(srcinfo) > 0
        let termbuf = get(srcinfo, 'termbuf')
        if term_getstatus(termbuf) == 'finished'
            let curwin = 1
            call win_gotoid(bufwinid(termbuf))
        elseif term_getstatus(termbuf) == 'running'
            echom 'still running'
            return
        endif
    endif
    let posinfo = s:GetPosInfo()
    if curwin
        call s:TermStart(a:cmd, 1, 0)
    else
        let vert = get(posinfo, 'vert')
        let rb = get(posinfo, 'rb')
        if rb
            exec "rightbelow call term_start(" .
                        \ "['bash', '-c', a:cmd]," .
                        \ "{'term_name': 'F5: ' . a:cmd,"
                        \ "'vertical': vert,"
                        \ "'curwin': 0})"
        else
            exec "leftabove call term_start(" .
                        \ "['bash', '-c', a:cmd]," .
                        \ "{'term_name': 'F5: ' . a:cmd,"
                        \ "'vertical': vert,"
                        \ "'curwin': 0})"
        endif
    endif
    let termbuf = bufnr('%')
    let termwin = win_getid()

    call setbufvar(srcbuf, s:src_field, {'termbuf': termbuf})
    call setbufvar(termbuf, s:term_field, {'srcbuf': srcbuf})
endfunc

" 编译或运行
" buffer和terminal一对一
func! f5#Run()
    if getbufvar(bufnr('%'), '&buftype') == 'terminal'
        let termbuf = bufnr('%')
        if term_getstatus(termbuf) != 'finished' | return | endif

        let terminfo = getbufvar(termbuf, s:term_field, {})
        if len(terminfo) == 0 | echom 'no bound source'| return | endif
        let srcbuf = get(terminfo, 'srcbuf')
        if !srcbuf || !bufexists(srcbuf) | echom 'source buffer not exists' | return | endif
        let srcwin = bufwinid(srcbuf)
        if srcwin == -1 | echom 'source buffer hidden' | return | endif
        call win_gotoid(srcwin)
    endif

    exec 'w'
    let cmd = s:GetCommand(&filetype)
    if len(cmd) == 0 | echom 'file type not supported' | return | endif
    call s:RunInShell(cmd)
endfunc

func! f5#ClearClosedTerm()
    " get terminal buffers
    let termbuf = []
    for bufid in filter(range(1, bufnr('$')), 'bufexists(v:val) && buflisted(v:val)')
        if getbufvar(bufid, '&buftype') == 'terminal'
            call add(termbuf, bufid)
            "let cmd = cmd . string(bufid) . ","
        endif
    endfor

    " get finished term
    let termfin = []
    for bufid in termbuf
        let info = getbufvar(bufid, s:term_field)
        if term_getstatus(bufid) == "finished" && len(info) != 0
            call add(termfin, bufid)
        endif
    endfor

    for bufid in termfin
        let cmd = string(bufid) . "bd"
        execute cmd
    endfor
endfunc

"=============================================================================
"     FileName: enhanced-object.vim
" 	InitalDate: 2020-03-26
"         Desc: Enhance the text object for wide char
"       Author: Troy Daniel
"        Email: Troy_Daniel@163.com
"     HomePage: https://www.cnblogs.com/troy-daniel
"      Version: 0.0.2
"   LastChange: 2021-03-09 12:16:39
"      History:
" 2020-12-16 [.] Bugfix, matching pair <> fails
" 2021-01-02 [+] Add the f/t moving operator
" 2021-01-07 [.] Modify the mappings into a for loop
" 	         [+] Mappings for normal mode
" 2021-01-11 [.] Bugfix: f' series fail. Cause: wrong escaping for '
" 2021-03-04 [.] Bugfix: the result for  f-char in normal and operator modes
" 				 are biased by one char
" 		 	 [+] Add v:count support, e.g. 3f(, 2T< are now supported
" 2021-03-05 [.] Change the mappings for key not given to the key itself
" 		 	 [.] Bugfix: the mapping for [ incorrectly included \
" 2021-03-09 [.] Make the search casesensitive for seeking chars
"
" Know bugs:
" 1. the pair '' and "" ignores comment char, e.g.
" for the stirng "string \" with comment char" will gives
" s    tring \
" instead of
"     string \"with comment char
"=============================================================================
" f/t move operator " {{{1
"
if exists("s:enhanced_object") 
	" || &ft == 'tex'
    finish
endif
" let loaded_enhanced_object = 1

let s:enhanced_object = {
	\ '<' : '[<《〈«‹]',
	\ '>' : '[>》〉»›]',
	\ "'" : "[''‘’`]",
	\ '"' : '["“”]',
	\ '(' : '[(（]',
	\ ')' : '[)）]',
	\ '[' : '[[【「〔『〖]',
	\ ']' : '[\]】」〕』〗]',
	\ '/' : '[/／]',
	\ }



" " }}}
" a/i operator " {{{1
" " }}}
" functions " {{{1
"
function! s:SearchEscape(str)
	return substitute(escape(a:str, '\.*[]/^$~'),'\n','\\n','ge')
endfunction

function! <Sid>GetCharUnderCursor()
	return nr2char(strgetchar(getline('.')[col('.') - 1:], 0))
endfunction

function! <Sid>EnhanceTextObject(inner, pat_left, pat_right) " {{{2

	" Record the current state of the visual region.
	let vismode = "v"


	" get char under cursor
	" let ch=nr2char(strgetchar(getline('.')[col('.') - 1:], 0))
	let ch=<sid>GetCharUnderCursor()

	let start = searchpairpos(a:pat_left, "", a:pat_right, 'bnW'.(ch =~ a:pat_left ? 'c': ''))
	let end   = searchpairpos(a:pat_left, "", a:pat_right, 'nW'.(ch =~ a:pat_right ? 'c': ''))

	" if the pair is different, previous statements work perfectly, however,
	" it'll fail when the pair is the same
	let startchar = nr2char(strgetchar(getline(start[0])[start[1]-1:], 0))
	let endchar = nr2char(strgetchar(getline(end[0])[end[1]-1:], 0))
	if(startchar =~ "['\"`]" || endchar =~ "['\"`]" )
		let start = searchpos(a:pat_left, 'bncW')
		let end   = searchpos(a:pat_right, 'nW')
	endif

	call cursor(start)
	if(a:inner)
		exe "normal! l"
	endif
	exe "normal! " . vismode
	" normal vismode
	call cursor(end)
	if(!a:inner)
		exe "normal! l"
	endif
endfunction
" }}}


function! MoveOperatorCursorPlace(pattern, direction, bVisual) " {{{2
	let b:ve = &virtualedit
	set virtualedit+=onemore
	" echo a:pattern
	if a:bVisual
		" normal "v"
		exe 'normal! v'
	endif
	call searchpos(a:pattern, (a:direction ==# 'f' ? '' : 'b' ) . 'w')
	let &virtualedit=b:ve
endfunction
" }}}


function! FTRun(direction_ch, mode) " {{{2
	let ch = nr2char(getchar())
	if ch !~ '[a-z ,.<>/?;:''"\[{\]}0-9`~!@#$%^&*()-=_+\\|]'
		return
	endif

	" echo 'The char is ' . ch . ' : ' . a:direction_ch . ' : ' . a:mode 
	call s:doFTRun(a:direction_ch, a:mode, ch)
endfunction
" }}}
function! s:getchar() " {{{2
  let c = getchar()
  if c =~ '^\d\+$'
    let c = nr2char(c)
  endif
  return c
endfunction
" }}}

" b:ft_last_command contains three bytes, corresponding to the parameters for
" function s:doFTRun(), e.g. [direction_ch, mode, ft_char]
let b:ft_last_command = ''
function! s:doFTRun(direction_ch, mode, ft_char) " {{{1
	let cnt = v:count > 0 ?  v:count : 1
	" echo 'cnt = ' . cnt
	" echo 'haskey ?= ' . has_key(s:enhanced_object, a:ft_char)
	let b:ve = &virtualedit
	set virtualedit+=onemore
	" echo 'Operator ' . a:direction_ch . a:mode . a:ft_char
	" call searchpos(a:pattern, (a:direction ==# 'f' ? '' : 'b' ) . 'w')
	let pattern = has_key(s:enhanced_object, a:ft_char) ? s:enhanced_object[a:ft_char] : s:SearchEscape(a:ft_char)


	" if in viusal mode, restart the selection from previous start
	if (a:mode =~ 'v')
		let cur_start = getpos("'<")
		let cur_end = getpos("'>") 
		if (a:direction_ch =~# "[FT]" )
			call cursor(cur_end[1], cur_end[2])
			exe 'normal! v'
			call cursor(cur_start[1], cur_start[2])
		else
			call cursor(cur_start[1], cur_start[2])
			exe 'normal! v'
			call cursor(cur_end[1], cur_end[2])
		endif
	endif

	" There is a tricky, in normal mode, the cursor ends at the match
	" However, to eat the match char in visual/operator mode, you should
	" one char away, that is, it eat the chars it passes.

	" construct pattern and search options
	" if a:direction_ch is T, don't include the char itself
	if (a:mode =~? '[vo]') || (a:direction_ch =~# '[FT]')
		let pattern =  pattern . (a:direction_ch =~# '[fT]' ? '\zs.' : '') . '\C'
	else
		" Making the searching casesensitive 2021-03-09
		let pattern =  (a:direction_ch =~# '[fT]' ? '' : '.\ze') . pattern . '\C'
	end
	" if a:direction_ch is f/t, search forward, otherwise backward
	let opt = (a:direction_ch =~# '[ft]' ? '' : 'b' ) . 'W'

	for ind in range(cnt)
		call searchpos( pattern , opt)
	endfor
	

	" store information and restore settings
	let b:ft_last_command = a:direction_ch . a:mode . a:ft_char
	let &virtualedit=b:ve
endfunction
" }}}

function! s:redoFTRun(dir_ch)
	if empty(b:ft_last_command)
		echoerr "No previous f/t operation"
		return
	endif
	let cmds = split(b:ft_last_command, '\zs')
	" Reverse direction for command ,
	" xor(char2nr('f'), char2nr('F')) = 32    
	" +----------------+----------------+
	" | 'f' ^ 'F' = 32 | 't' ^ 'T' = 32 |
	" | 'f' ^ 32 = 'F' | 't' ^ 32 = 'T' |
	" | 'F' ^ 32 = 'f' | 'T' ^ 32 = 't' |
	" +----------------+----------------+
	" xor(char2nr('f'), char2nr('F'))
	let direction_ch = nr2char(xor(char2nr(cmds[0]), a:dir_ch ==? ';' ? 0 : 32))
	" echomsg direction_ch
	call s:doFTRun(direction_ch, cmds[1], cmds[2])
endfunction

" " }}}
" mappings " {{{1
nnoremap ; :call <sid>redoFTRun(';')<cr>
nnoremap , :call <sid>redoFTRun(',')<cr>
vnoremap ; :<C-U>call <sid>redoFTRun(';')<cr>
vnoremap , :<C-U>call <sid>redoFTRun(',')<cr>

vnoremap f :<c-u>call FTRun('f', 'v')<cr>
onoremap f :<c-u>call FTRun('f', 'o')<cr>
nnoremap f :<c-u>call FTRun('f', 'n')<cr>
vnoremap F :<c-u>call FTRun('F', 'v')<cr>
onoremap F :<c-u>call FTRun('F', 'o')<cr>
nnoremap F :<c-u>call FTRun('F', 'n')<cr>
vnoremap T :<c-u>call FTRun('T', 'v')<cr>
onoremap T :<c-u>call FTRun('T', 'o')<cr>
nnoremap T :<c-u>call FTRun('T', 'n')<cr>
vnoremap t :<c-u>call FTRun('t', 'v')<cr>
onoremap t :<c-u>call FTRun('t', 'o')<cr>
nnoremap t :<c-u>call FTRun('t', 'n')<cr>


onoremap <silent>a> :<C-u>cal <Sid>EnhanceTextObject(0, '[<《〈«‹]', '[>》〉»›]')<CR>
onoremap <silent>i> :<C-u>cal <Sid>EnhanceTextObject(1, '[<《〈«‹]', '[>》〉»›]')<CR>
vnoremap <silent>a> :<C-u>cal <Sid>EnhanceTextObject(0, '[<《〈«‹]', '[>》〉»›]')<CR>
vnoremap <silent>i> :<C-u>cal <Sid>EnhanceTextObject(1, '[<《〈«‹]', '[>》〉»›]')<CR>

onoremap <silent>a< :<C-u>cal <Sid>EnhanceTextObject(0, '[<《〈«‹]', '[>》〉»›]')<CR>
onoremap <silent>i< :<C-u>cal <Sid>EnhanceTextObject(1, '[<《〈«‹]', '[>》〉»›]')<CR>
vnoremap <silent>a< :<C-u>cal <Sid>EnhanceTextObject(0, '[<《〈«‹]', '[>》〉»›]')<CR>
vnoremap <silent>i< :<C-u>cal <Sid>EnhanceTextObject(1, '[<《〈«‹]', '[>》〉»›]')<CR>

onoremap <silent>a( :<C-u>cal <Sid>EnhanceTextObject(0, '[(（]', '[)）]')<CR>
onoremap <silent>i( :<C-u>cal <Sid>EnhanceTextObject(1, '[(（]', '[)）]')<CR>
vnoremap <silent>a( :<C-u>cal <Sid>EnhanceTextObject(0, '[(（]', '[)）]')<CR>
vnoremap <silent>i( :<C-u>cal <Sid>EnhanceTextObject(1, '[(（]', '[)）]')<CR>

onoremap <silent>a) :<C-u>cal <Sid>EnhanceTextObject(0, '[(（]', '[)）]')<CR>
onoremap <silent>i) :<C-u>cal <Sid>EnhanceTextObject(1, '[(（]', '[)）]')<CR>
vnoremap <silent>a) :<C-u>cal <Sid>EnhanceTextObject(0, '[(（]', '[)）]')<CR>
vnoremap <silent>i) :<C-u>cal <Sid>EnhanceTextObject(1, '[(（]', '[)）]')<CR>

onoremap <silent>a[ :<C-u>cal <Sid>EnhanceTextObject(0, '[[【「〔『〖]', '[]】」〕』〗]')<CR>
onoremap <silent>i[ :<C-u>cal <Sid>EnhanceTextObject(1, '[[【「〔『〖]', '[]】」〕』〗]')<CR>
vnoremap <silent>a[ :<C-u>cal <Sid>EnhanceTextObject(0, '[[【「〔『〖]', '[]】」〕』〗]')<CR>
vnoremap <silent>i[ :<C-u>cal <Sid>EnhanceTextObject(1, '[[【「〔『〖]', '[]】」〕』〗]')<CR>


onoremap <silent>a] :<C-u>cal <Sid>EnhanceTextObject(0, '[[【「〔『〖]', '[]】」〕』〗]')<CR>
onoremap <silent>i] :<C-u>cal <Sid>EnhanceTextObject(1, '[[【「〔『〖]', '[]】」〕』〗]')<CR>
vnoremap <silent>a] :<C-u>cal <Sid>EnhanceTextObject(0, '[[【「〔『〖]', '[]】」〕』〗]')<CR>
vnoremap <silent>i] :<C-u>cal <Sid>EnhanceTextObject(1, '[[【「〔『〖]', '[]】」〕』〗]')<CR>

onoremap <silent>a" :<C-u>cal <Sid>EnhanceTextObject(0, '["“]', '["”]')<CR>
onoremap <silent>i" :<C-u>cal <Sid>EnhanceTextObject(1, '["“]', '["”]')<CR>
vnoremap <silent>a" :<C-u>cal <Sid>EnhanceTextObject(0, '["“]', '["”]')<CR>
vnoremap <silent>i" :<C-u>cal <Sid>EnhanceTextObject(1, '["“]', '["”]')<CR>

onoremap <silent>a' :<C-u>cal <Sid>EnhanceTextObject(0, "['‘`]", "['’`]")<CR>
onoremap <silent>i' :<C-u>cal <Sid>EnhanceTextObject(1, "['‘`]", "['’`]")<CR>
vnoremap <silent>a' :<C-u>cal <Sid>EnhanceTextObject(0, "['‘`]", "['’`]")<CR>
vnoremap <silent>i' :<C-u>cal <Sid>EnhanceTextObject(1, "['‘`]", "['’`]")<CR>






" " }}}
" vim: fdm=marker fdl=0
"

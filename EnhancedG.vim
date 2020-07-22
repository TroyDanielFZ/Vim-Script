" Author: Troy Daniel
" EMail: Troy_Daniel@163.com
" Date: 2020-07-22 
" Description:
"    The power of `g` command is so charming, and I'm additted to it.
"    However, I somethimes encounter a problem when handling text: I want to
"    handle text that is feature-less, but there are features at the former or
"    latter lines. For instance, giving the next several lines
"        a b c
"        e d f
"        1 2 3
"        d b c
"        e k l
"        2 4 4
"        d b c
"        e d f
"    I want to delete the lines that contains characeter [a-z], only when the
"    next contains digits [0=9], at present, the only way hit my mind is to
"    use a complicate regular expression, something like:
"    	:g/.\{-}[a-z].*\n.\{-}[0-9]/d
"    It works when the problem is simple. However, it is costly and bored when
"    things get a little bit more complicate, as I described in the question 
"
" 	 Therefore, I write this script to fullfil my wish to easy handle this
" 	 kind of problem. For example, the above example can be hanled by:
" 	 	:G/[a-z]/+/[0-9]/d
" 	 For more explanation, go on.
"
" 	 The command G is follows by several filters, one or more, as many as you
" 	 want, and at last, a stand ex-command, default to be |:print|.
"
" 	 A filter is in the form:
" 	 	[+-]\d[!]/regular expressions/
" 	 \d  -  offset in lines, if no +/- is given, the offset is set to 0 unless
" 	 		digits given; However, if +/1 is given, the offset is set to 1
" 	 		unless digits are given.
" 	 +/- -  Indicating the direction, + for lines below current line, and -
" 	 		for lines above current line.
" 	 !   -  if ! is given, the lines match regular expression will be
" 	 		excluded, otherwise, the lines do not match regular expression will 
" 	 		be exclude.
"
" 	 example,
" 		+/\d/             - the next line contains at lest a digit
" 		-/\d/             - the previous line contains at lest a digit
" 		/\d/              - current line contains at lest a digit
" 		-2!/\d/           - if the second line above current line doesn't
" 							contains any digit
" 		-200!/\s/         - if the 200th line below current line doesn't
" 							contains any space
" 	 Moreover, all the lines the filters involves must be with the given
" 	 range, otherwise ignored.
" 	 example,
" 	 +200/\d/         - the last 200 lines will never match the
" 	 					requirements, buth the 201st from the EOF may
" 	 -200/\d/         - the first 200 lines will never match the
" 	 					requirements, buth the 201st may
"
"    At last, the ex-command will be perfrom on the lines that match the
"    requirements. Moreover, normal offset can be used as usual.
"    example,
"    	G/\s/+/\d/-j
"        |  ||   ||------------------------------- the final ex-command
"        |  |-----
"        ----  |---------------------------------- The second requirement
"         |--------------------------------------- the first requirement
"
"
"   Write at the end:
"   	I'm not quite familiar to with vim script, so there may be bugs. If
"   	you found, please let me know. Besides,    this script may not be
"   	so efficient as I expecte, and any enhancement will be appreciated.
"

function! EnhancedG(filter) range
	let all_lines = a:lastline - a:firstline + 1
	let matched = repeat([1], a:lastline - a:firstline + 1)
	let filter = a:filter
	" get all the filters
	let all_command = []
	call substitute(a:filter, '[-+]\?\d*!\?\/\(\\.\|[^\\]\)\{-}\/', '\=add(all_command, submatch(0)) ', 'g')
	" retrive the final command, default is :print
	let last_comm =  substitute(a:filter, '[-+]\?\d*!\?\/\(\\.\|[^\\]\)\{-}\/', '', 'g')
	let last_comm =  (last_comm == '' ? 'p' : last_comm)
	for comm in all_command
		let index = 0
		while index < all_lines
			if matched[index]
				let bias = matchstr(comm, '^[-+]\?\d*')
				let bias = str2nr(bias =~ '^$' ? '0' : (bias =~ '^[-+]$' ? bias . '1': bias))
				let nline = index + bias + a:firstline
				if nline > a:lastline
					while index < all_lines
						let matched[index] = 0
						let index += 1
					endwhile
				elseif nline < a:firstline
					let index = bias - 1
					while index >= 0
						let matched[index] = 0
						let index -= 1
					endwhile
					let index = bias - 1
				else
					let needle = matchstr(comm, '^[-+]\?\d*!\?/\zs.*\ze/')
					" exclude ?
					if matchstr(comm, '^[-+]\?\d*\zs!\?') =~ '!'
						if getline(nline) =~ needle
							let matched[index] = 0
						endif
					else
						if getline(nline) !~ needle
							let matched[index] = 0
						endif
					endif
				endif
			endif
			let index += 1
		endwhile
		" let bias = matchstr(comm, '^[-+]\?\d*')
		" let bias = str2nr(bias =~ '^$' ? '0' : (bias =~ '^[-+]$' ? bias . '1': bias))
		" echo 'bias    = ' . bias
		" echo 'include = ' . (matchstr(comm, '^[-+]\?\d*\zs!\?') =~ '!' ? 0 : 1)
		" echo 'comm    = ' . matchstr(comm, '^[-+]\?\d*!\?/\zs.*\ze/')
		" echo matched
		" echo '----------------------------------------'
	endfor
	let index = all_lines - 1
	while index >= 0
		if matched[index]
			let cur = index + a:firstline
			exe cur . last_comm
		endif
		let index -= 1
	endwhile
endfunction

command! -nargs=1 -complete=command -range=% -bar G <line1>,<line2>call EnhancedG(<q-args>)
" 1,3G/fun one\\\//+3!/func two/-3/func three//nobias/
" 1,3G/[a-z0-9]/+1!/[a-z]/d

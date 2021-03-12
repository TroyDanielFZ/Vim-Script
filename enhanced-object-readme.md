`enhanced-object.vim` provides two series of commands:
1. `f/F/t/T` to locate a character, with support to locate the non-Ascii characters.
2. `vi/va` operation succeeded a character, with support to match Chinese symbol `“”「」` etc.


# FT Operation

## Features

I call this function as `FT` opeation, since it acts like the original
`f/t/F/T` operations, and with the following ehancement:

1. It can search non-Ascii characters, for instance, in the following sencents,
   with `|` indicates the cursor position

	```
	|这句话里含有“引号”，以及（括号）。
	再来一句，这句话里含有“引号”，以及（括号）。
	```
	then if you press `f"`, it cursor will move to 
	```
	这句话里含有|“引号”，以及（括号）。
	再来一句，这句话里含有“引号”，以及（括号）。
	```
	covering the `“` character in vim.

2. Forward/backward beyond lines. If the cursor is currently at
	```
	|这句话里含有“引号”，以及（括号）。
	再来一句，这句话里含有“引号”，以及（括号）。
	```
	after you press `3f"`, it becomes
	```
	这句话里含有“引号”，以及（括号）。
	再来一句，这句话里含有|“引号”，以及（括号）。
	```

## Customization

If you want it to support your own characters, just change the variable
`s:enhanced_object`, which is currently defined as 

```vim
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
```


# Ehanced text object for `;"[{(<`

## Features

It's not difficult to comprehence that, if the curosr is currently at

```
这句话里含有“|引号”，以及（括号）。
再来一句，这句话里含有“引号”，以及（括号）。
```

then if you press `va"`, it will visual select `“|引号”` at the first line.



## Customization
	
Just change the second and the thrid parameters in `EnhanceTextObject` to your
own pattern, and append to the file/write to you own vimrc/modify the original
ones in the script.

```vim
onoremap <silent>a' :<C-u>cal <Sid>EnhanceTextObject(0, "['‘`]", "['’`]")<CR>
onoremap <silent>i' :<C-u>cal <Sid>EnhanceTextObject(1, "['‘`]", "['’`]")<CR>
vnoremap <silent>a' :<C-u>cal <Sid>EnhanceTextObject(0, "['‘`]", "['’`]")<CR>
vnoremap <silent>i' :<C-u>cal <Sid>EnhanceTextObject(1, "['‘`]", "['’`]")<CR>
```

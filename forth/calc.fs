variable ptr   \ pointer to the string we're parsing
variable len   \ length of the string
variable index \ index to the next character to parse

: rewind           0 index ! ;
: advance  ( -- )  index @ 1 + index ! ;

: ?eof ( -- f )    index @ len @ >= ;
: peek  ( -- c )
  ?eof if
    s" eof" exception throw
  else
    ptr @ index @ + c@
  then ;

: parse ( string len -- ) len ! ptr ! rewind ;
: fail    false ;
: success true ;

: digit? ( c -- f )
  dup [char] 0 >=
  swap [char] 9 <=
  and ;

: digit ( -- n true | false )
  peek dup digit? if
    advance
    [char] 0 - success
  else
    drop fail
  then ;

: number ( -- n true | false )
  peek digit? if
    0
    begin digit while
      swap 10 * +
    repeat success
  else
    fail
  then ;

1 constant OP_ADD
2 constant OP_SUB
: op ( -- op true | false )
  peek
  dup [char] + = if drop advance OP_ADD success exit then
  dup [char] - = if drop advance OP_SUB success exit then
  fail ;

: <then> invert if fail rdrop then ;

: calc ( -- a op b true | false )
  number <then> op <then> number ;

: start s" 199+331" parse ;

variable ptr   \ pointer to the string we're parsing
variable len   \ length of the string
variable index \ index to the next character to parse

: parse ( string len -- ) len ! ptr ! rewind ;

: rewind           0 index ! ;
: peek  ( -- c )   ptr @ index @ + c@ ;
: advance  ( -- )  index @ 1 + index ! ;

: digit? ( c -- flag )
  dup [char] 0 >=
  swap [char] 9 <=
  and ;

: fail    false ;
: success true ;

: digit ( -- flag )
  peek dup digit? if
    advance
    [char] 0 - success
  else
    drop fail
  then ;

: number
  peek digit? if
    0
    begin digit while
      swap 10 * +
    repeat success
  else
    fail
  then ;

: start s" 199+331" parse ;

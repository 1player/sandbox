variable ptr   \ pointer to the string we're parsing
variable len   \ length of the string
variable index \ index to the next character to parse

: rewind           0 index ! ;
: advance  ( -- )  index @ 1 + index ! ;

: ?eof ( -- f )    index @ len @ >= ;
: peek  ( -- c true | false )
  ?eof if
    false
  else
    ptr @ index @ + c@ true
  then ;

: parse ( string len -- ) len ! ptr ! rewind ;
: fail    false ;
: success true ;
: <then> \ execute following words iff TOS is true
  invert if fail rdrop then ;

: ?digit  ( c -- f )
  dup [char] 0 >=
  swap [char] 9 <=
  and ;

: digit ( -- n true | false )
  peek <then> dup ?digit if
    advance
    [char] 0 - success
  else
    drop fail
  then ;

: number ( -- n true | false )
  peek <then> ?digit if
    0
    begin digit while
      swap 10 * +
    repeat success
  else
    fail
  then ;

: plus peek <then> [char] + = if advance success else fail then ;

: do-add  ( a b -- )  + . ;
: calc
  number <then> plus <then> number <then> do-add ;

s" 199+331" parse calc

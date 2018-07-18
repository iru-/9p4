warnings off
include mf/mf.f

( Format conversion )
: 1@  ( a -- n )  c@ ;
: 2@  ( a -- n )  a! c@+  c@+ 8 lshift or ;
  
: 4@  ( a -- n ) 
  a! c@+
  c@+  8 lshift or
  c@+ 16 lshift or
  c@+ 24 lshift or ;

: 8@  ( a -- n )
  a! c@+
  c@+  8 lshift or
  c@+ 16 lshift or
  c@+ 24 lshift or
  c@+ 32 lshift or
  c@+ 40 lshift or
  c@+ 48 lshift or
  c@+ 56 lshift or ;

: s@  ( a -- a n )    dup 2 + swap 2@ ;

: 1!  ( n a -- )  c! ;
: 2!  ( n a -- )  a!  dup c!+  8 rshift c!+ ;

: 4!  ( n a -- )
  a! dup c!+
  dup  8 rshift c!+
  dup 16 rshift c!+
      24 rshift c!+ ;

: 8!  ( n a -- )
  a! dup c!+
  dup  8 rshift c!+
  dup 16 rshift c!+
  dup 24 rshift c!+
  dup 32 rshift c!+
  dup 40 rshift c!+
  dup 48 rshift c!+
      56 rshift c!+ ;

: s!  ( a n dst -- )  2dup 2!  2 + swap move ;

( Transmission/reception buffers )
8192 constant /buf

create txbuf  /buf allot
create tx# 0 ,

: txcur   ( -- a )  txbuf tx# @ + ;
: tx+     ( n -- )  tx# +! ;

: tx(  ( -- )      4 tx# ! ;
: )tx  ( -- a n )  tx# @ txbuf 4!  txbuf tx# @ ;


: tx1!  ( n -- )    txcur 1!  1 tx+ ;
: tx2!  ( n -- )    txcur 2!  2 tx+ ;
: tx4!  ( n -- )    txcur 4!  4 tx+ ;
: tx8!  ( n -- )    txcur 8!  8 tx+ ;
: txs!  ( a n -- )  dup push  txcur s!  pop 2 + tx+ ;

: txdump  ( -- )  txbuf tx# @ dump ;


create rxbuf  /buf allot
create rx# 0 ,

: rxcur   ( -- a )  rxbuf rx# @ + ;
: rx+     ( n -- )  rx# +! ;

: rx1@  ( -- n )    rxcur 1@  1 rx+ ;
: rx2@  ( -- n )    rxcur 2@  2 rx+ ;
: rx4@  ( -- n )    rxcur 4@  4 rx+ ;
: rx8@  ( -- n )    rxcur 8@  8 rx+ ;
: rxs@  ( -- a n )  rxcur s@  dup 2 + rx+ ;

: rx  ( -- a n )  rxbuf /buf ;  \ address where to read the data

( Utilities )
create curtag 0 ,
: tag  ( -- n )
  curtag @  dup 1 + 65535 mod  curtag ! ;

4294967295 constant NOFID
create curfid 0 ,
: newfid  ( -- n )
  curfid @  dup 1 + NOFID mod  curfid ! ;

\ Qid
13 constant /qid
: qtype     ( a -- n )  1@ ;
: qversion  ( a -- n )  1 + 4@ ;
: qpath     ( a -- n )  5 + 8@ ;
: qnew      ( a -- a )  /qid allocate throw  dup push  /qid move  pop ;

: .qfield    ( n -- )  s>d <# #s #> type ;
: .qtype     ( a -- )  qtype    .qfield ;
: .qversion  ( a -- )  qversion .qfield ;
: .qpath     ( a -- )  qpath    .qfield ;
: .qid  ( a -- )
  dup dup  ." (" hex .qpath decimal space .qversion space .qtype ." )" ;

\ Addresses valid for every R-message
: size@  ( a -- a )  4@ ;
: type@  ( a -- a )  4 + 1@ ;
: tag@   ( a -- a )  5 + 2@ ;
: body   ( a -- a )  7 + ;

\ Error on short reads or wrong response type
: rxerror?  ( n type -- )
  rxbuf type@ <>  swap rxbuf size@ <>   or ;

( 9P messages )

: Tversion  ( -- a n )  tx( 100 tx1!  tag tx2!  8192 tx4! s" 9P2000" txs! )tx ;

: Rversion  ( n -- a n msize )
  101 rxerror? if 0 0 0 exit then
  rxbuf body dup push  4 + s@  pop 4@ ;

: Tattach   ( uname aname -- a n fid )
  tx(
    104 tx1!  tag tx2!
    newfid dup push tx4!
    NOFID tx4!  push push txs! pop pop txs!
    pop                                                                                                 
  )tx ;

: Rattach  ( n -- a )
  105 rxerror? if 0 exit then
  rxbuf body ;

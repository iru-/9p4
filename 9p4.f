: c!+ ( c a -> a+1 )    swap over  c!  1+ ;

( Format conversion )
: be1@ ( a -> n )    c@ ;
: be2@ ( a -> n )    c@+ swap  c@ 8 lshift or ;

: be4@ ( a -> n )
    c@+ swap
    c@+  8 lshift  swap
    c@+ 16 lshift  swap
    c@  24 lshift
    or or or ;

: be8@ ( a -> n )
    c@+ swap
    c@+  8 lshift  swap
    c@+ 16 lshift  swap
    c@+ 24 lshift  swap
    c@+ 32 lshift  swap
    c@+ 40 lshift  swap
    c@+ 48 lshift  swap
    c@  56 lshift
    or or or or or or or ;

: 9p-s@ ( a -> a u )    dup 2 +  swap be2@ ;

: be1! ( n a -> )    c! ;

: be2! ( n a -> )
    over swap  c!+
    swap 8 rshift
    swap c! ;

: be4! ( n a -> )
    over >r  c!+
    r@ 08 rshift  swap c!+
    r@ 16 rshift  swap c!+
    r> 24 rshift  swap c! ;

: be8! ( n a -> )
    over >r  c!+
    r@ 08 rshift  swap c!+
    r@ 16 rshift  swap c!+
    r@ 24 rshift  swap c!+
    r@ 32 rshift  swap c!+
    r@ 40 rshift  swap c!+
    r@ 48 rshift  swap c!+
    r> 56 rshift  swap c! ;

: 9p-s! ( src n dst -> )    2dup be2!  2 + swap move ;


( Transmission/reception buffers )
8192 constant /buf

create txbuf  /buf allot
create tx# 0 ,

: txcur ( -> a )    txbuf tx# @ + ;
: tx+ ( n -> )      tx# +! ;

: tx1! ( n -> )    txcur be1!  1 tx+ ;
: tx2! ( n -> )    txcur be2!  2 tx+ ;
: tx4! ( n -> )    txcur be4!  4 tx+ ;
: tx8! ( n -> )    txcur be8!  8 tx+ ;

: txs! ( a u -> )    dup >r  txcur 9p-s!  r> 2 +  tx+ ;
: >tx ( a u -> )    tuck  >r txcur r> move  tx+ ;


create rxbuf  /buf allot
create rx# 0 ,

: rxcur ( -> a )    rxbuf rx# @ + ;
: rx+ ( n -> )      rx# +! ;

: rx1@ ( -> n )    rxcur be1@  1 rx+ ;
: rx2@ ( -> n )    rxcur be2@  2 rx+ ;
: rx4@ ( -> n )    rxcur be4@  4 rx+ ;
: rx8@ ( -> n )    rxcur be8@  8 rx+ ;

: rxs@ ( -> a u )    rxcur 9p-s@  dup 2 + rx+ ;

: 9p-rxbuf ( -> a u )    rxbuf /buf ;


( 9P utilities )
create curtag 0 ,
: tag ( -> n )
    curtag @
    dup  1 + 65535 mod
    curtag ! ;

4294967295 constant NOFID
create curfid 0 ,
: newfid ( -> n )
    curfid @
    dup  1 + NOFID mod
    curfid ! ;

: tx[ ( type -> )   4 tx# !  tx1!  tag tx2! ;
: ]tx ( -> a u )    tx# @  txbuf be4!  txbuf tx# @ ;

struct
    1 1 field qid-type
    1 4 field qid-version
    1 8 field qid-path
end-struct %qid
%qid nip constant /qid

struct
    1 2  field stat-size
    1 2  field stat-type
    1 4  field stat-dev
    %qid field stat-qid
    1 4  field stat-mode
    1 4  field stat-atime
    1 4  field stat-mtime
    1 8  field stat-length
end-struct %stat-base
%stat-base nip constant /stat-base

: stat-name ( a -> 'name )    /stat-base + ;
: stat-uid ( a -> 'uid )      stat-name 9p-s@ + ;
: stat-gid ( a -> 'gid )      stat-uid  9p-s@ + ;
: stat-muid ( a -> 'muid )    stat-gid  9p-s@ + ;

\ Addresses valid for every R-message
: 9p-size@ ( a -> msg-size )    be4@ ;
: 9p-type@ ( a -> msg-type )    4 + be1@ ;
: 9p-tag@  ( a -> msg-tag )     5 + be2@ ;
: 9p-body ( a -> 'msg-body )    7 + ;

\ Error on short reads or wrong response type
: rxerror? ( msg-size type -> flag )
    rxbuf 9p-type@ <>  swap rxbuf 9p-size@ <>  or ;

( 9P messages )
: Tversion ( -> a u )    100 tx[ 8192 tx4! s" 9P2000" txs! ]tx ;

: Rversion ( msg-size -> a u msize )
    101 rxerror? if  0 0 0 exit  then
    rxbuf 9p-body  dup >r
    4 + 9p-s@
    r> be4@ ;

: Tattach ( 'uname n1 'aname n2 -> rootfid a u )
    104 tx[
        newfid dup >r  tx4!
        NOFID tx4!
        >r >r  txs!
        r> r>  txs!
        r>
    ]tx ;

: Rattach ( msg-size -> 'qid )
    105 rxerror? if  0 exit  then
    rxbuf 9p-body ;

: Twalk ( 'name #name ... #names fid -> newfid a u )
    110 tx[
        tx4!
        newfid  dup >r  tx4!
        dup tx2!
        dup if
            1- for txs! next
        else
            drop
        then
        r>
    ]tx ;

: clonefid ( fid -> newfid a u )    0 swap Twalk ;

: Rwalk ( msg->size -> 'qids #qids )
    111 rxerror? if  0 -1 exit  then
    rxbuf 9p-body  dup 2 +  swap be2@ ;

: Topen ( fid mode -> a u )
    112 tx[
        swap tx4! tx1!
    ]tx ;

: Tcreate ( fid 'name #name perm mode -> a u )
    114 tx[
        >r >r 2>r
        tx4!  2r> txs!  r> tx4!  r> tx1!
    ]tx ;

: Ropencreate ( n type -> 'qid iounit )
    rxerror? if  0 0 exit  then
    rxbuf 9p-body  dup /qid + be4@ ;

: Ropen ( n -> 'qid iounit )      113 Ropencreate ;
: Rcreate ( n -> 'qid iounit )    115 Ropencreate ;

: rw ( fid offset count -> )
    >r >r tx4!  r> tx8!  r> tx4! ;

: Tread ( fid offset count -> a u )
    116 tx[ rw ]tx ;

: Rread ( n -> data count )
    117 rxerror? if  0 0 exit  then
    rxbuf 9p-body  dup be4@  swap 4 + swap ;

: Twrite ( fid offset data count -> a u )
    tuck >r >r
    118 tx[
        rw
        r> r> >tx
    ]tx ;

: Rwrite ( n -> count )
    119 rxerror? if  0 exit  then
    rxbuf 9p-body be4@ ;

: Tclunkremove ( fid type -> a u )    tx[ tx4! ]tx ;
: Rclunkremove ( n type -> )          rxerror? if exit then ;

: Tclunk ( fid -> a u )    120 Tclunkremove ;
: Rclunk ( n -> )          121 Rclunkremove ;

: Tremove ( fid -> a u )    122 Tclunkremove ;
: Rremove ( fid -> a u )    123 Rclunkremove ;

: Tstat ( fid -> a u )    124 tx[ tx4! ]tx ;

: Rstat ( n -> 'stat len )
    125 rxerror? if  0 exit  then
    rxbuf 9p-body  dup 2 +  swap be2@ ;

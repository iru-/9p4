require unix/socket.fs
require 9p4.f

warnings off
0 value mysock
: connect ( a u port -> )    open-socket to mysock ;
: write ( a u -> )           mysock write-socket ;
: read ( -> n )              mysock 9p-rxbuf read-socket nip ;

: ?abort ( flag a u -> )
    >r >r if
        ." error: "  r> r> type abort
    then
    r> drop r> drop ;

: .qfield ( n -> )      s>d <# #s #> type ;
: .qtype  ( a -> )      qid-type le1@  .qfield ;
: .qversion ( a -> )    qid-version le4@  decimal .qfield ;
: .qpath ( a -> )       qid-path le8@  hex .qfield ;
: .qid ( a -> )
    base @ >r
    ." ("  dup .qpath  space  dup .qversion  space .qtype  ." )"
    r> base ! ;

: .qids ( a u -> )
    1- for
        dup  .qid space  /qid +
    next
    drop ;

: .mode ( u -> )    base @ >r    8 base !  .    r> base ! ;

: .stat ( 'stat len -> )
    drop
    ." size  : "  dup stat-size   le2@ . cr
    ." type  : "  dup stat-type   le2@ . cr
    ." dev   : "  dup stat-dev    le4@ . cr
    ." qid   : "  dup stat-qid         .qid  cr
    ." mode  : "  dup stat-mode   le4@ .mode cr
    ." atime : "  dup stat-atime  le4@ . cr
    ." mtime : "  dup stat-mtime  le4@ . cr
    ." length: "  dup stat-length le8@ . cr
    ." name  : "  dup stat-name   9p-s@ type cr
    ." uid   : "  dup stat-uid    9p-s@ type cr
    ." gid   : "  dup stat-gid    9p-s@ type cr
    ." muid  : "      stat-muid   9p-s@ type cr ;


s" 127.0.0.1" 9999 connect

Tversion write
read Rversion
." connection msize: " . cr
." protocol version: " type cr

cr
-1 value rootfid
s" iru" s" " Tattach write to rootfid  read Rattach
." root fid: " rootfid . cr
." root qid: " .qid cr

cr
rootfid clonefid write
." root clone fid: " . cr  read Rwalk
." #qids walked  : " . cr  drop  \ drop pointer to array of qids

cr
-1 value rfid
s" /etc/hosts" 1 rootfid Twalk write  to rfid
." read fid    : " rfid . cr  read Rwalk
." #qids walked: " dup . cr
." qids        : " .qids cr

cr
s" hosts" s" etc" 2 rootfid Twalk write
." final fid   : " . cr  read Rwalk
." #qids walked: " dup . cr
." qids        : " .qids cr

cr
rfid 0 Topen write  read Ropen
." opened: " rfid . cr
." iounit: " . cr
." qid   : " .qid cr

cr
rfid 0 32 Tread write  read Rread
." #read: " dup . cr
." --- " cr
type cr
." --- " cr

cr
-1 value dirfid
s" /tmp" 1 rootfid Twalk write  to dirfid
." dir fid: " dirfid . cr  read Rwalk  -1 = s" can't walk to dir" ?abort  drop

dirfid s" aaa" 420 1 Tcreate write  read Rcreate
over 0 = s" can't create file" ?abort
." created!" cr
." iounit: " . cr
." qid   : " .qid cr

dirfid Tclunk write  read Rclunk

cr
-1 value wfid
s" /tmp/aaa" 1 rootfid Twalk write  to wfid
." write fid: " wfid . cr  read Rwalk  -1 = s" can't walk to file" ?abort  drop

wfid 1 Topen write  read Ropen  drop drop
wfid 0 s" written by 9p4" Twrite write  read Rwrite
." #written : " . cr

cr
wfid Tstat write  read Rstat over swap .stat
constant wstat

\ change name, mode and group of the file
stat-dont-touch wstat stat-type le2!
stat-dont-touch wstat stat-dev  le4!

stat-dont-touch wstat stat-qid qid-type le1!
stat-dont-touch wstat stat-qid qid-version le4!
stat-dont-touch wstat stat-qid qid-path le8!

421 wstat stat-mode le4!
stat-dont-touch wstat stat-atime le4!
stat-dont-touch wstat stat-mtime le4!
stat-dont-touch wstat stat-length le8!

s" abc" wstat stat-name 9p-s!
stat-s-dont-touch wstat stat-uid 9p-s!
s" wheel"  wstat stat-gid  9p-s!
stat-s-dont-touch wstat stat-muid 9p-s!

wstat wfid Twstat write read Rwstat
wfid Tstat write  read Rstat cr .stat

wfid Tremove write  read Rremove
rootfid Tclunk write
bye

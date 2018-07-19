require unix/socket.fs
require 9p4.f

0 value mysock
: connect  ( a n port -- )  open-socket to mysock ;
: write    ( a n -- )       mysock write-socket ;
: read     ( -- n )         mysock rx read-socket nip ;

: .qids    ( a n -- )
  for dup .qid space /qid + next drop ;

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
rootfid clonefid  ." root clone fid: " . cr
write read Rwalk  ." #qids walked  : " . cr

cr
-1 value rfid
s" /etc/hosts" 1 rootfid Twalk  dup to rfid
." read fid    : " . cr   write read Rwalk
." #qids walked: " dup . cr
." qids        : " .qids cr

cr
s" hosts" s" etc" 2 rootfid Twalk
." final fid   : " . cr  write read Rwalk
." #qids walked: " dup . cr
." qids        : " .qids cr

cr
rfid 0 Topen write  read Ropen
." opened: " rfid . cr
." iounit: " . cr
." qid   : " .qid cr

rfid 0 32 Tread write  read Rread
." #read: " dup . cr
." --- " cr
type cr
." --- " cr

cr
-1 value wfid
s" /tmp/aaa" 1 rootfid Twalk  dup to wfid
." write fid: " . cr  write read Rwalk drop drop
wfid 1 Topen write read Ropen drop drop
wfid 0 s" written by 9p4" Twrite write  read Rwrite
." #written : " . cr

bye

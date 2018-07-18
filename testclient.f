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
-1 value hfid
s" /etc/hosts" 1 rootfid Twalk  dup to hfid
." hosts fid   : " . cr   write read Rwalk
." #qids walked: " dup . cr
." qids        : " .qids cr

cr
s" hosts" s" etc" 2 rootfid Twalk
." final fid   : " . cr  write read Rwalk
." #qids walked: " dup . cr
." qids        : " .qids cr

cr
hfid 0 Topen write  read Ropen
." opened: " hfid . cr
." iounit: " . cr
." qid   : " .qid cr

hfid 0 32 Tread write  read Rread
." #read: " dup . cr
." --- " cr
type cr
." --- " cr
bye

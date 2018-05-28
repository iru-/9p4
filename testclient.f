require unix/socket.fs
require 9p4.f

0 value mysock
: connect  ( a n port -- )  open-socket to mysock ;
: write    ( a n -- )       mysock write-socket ;
: read     ( -- n )         mysock rx read-socket nip ;

s" 127.0.0.1" 9999 connect

Tversion write
read Rversion
cr ." msize: " .
cr ." vers : " type

-1 value rootfid
s" iru" s" " Tattach write to rootfid
read Rattach

bye

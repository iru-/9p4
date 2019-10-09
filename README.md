9p4
===

9p4 is an implementation of the 9P protocol in gforth [1]. It provides routines
for encoding and decoding 9P [2] [3] messages, along with auxiliary routines for
implementing 9P clients and servers.

The remainder of this document assumes familiarity with 9P and its messages.


## Data structures

The fields in a 9p4 data structure are named `prefix-field`, where `prefix` is
the 9P data structure/concept name.

#### Qid

* `qid-type ( 'qid -> 'qid-type )`
* `qid-version ( 'qid -> 'qid-version )`
* `qid-path ( 'qid -> 'qid-path )`
* `qid% ( -> qid-alignment #qid )`: for use with gforth struct allocation routines
* `/qid ( -> #qid )`: size of `qid` structure


#### Stat
* `stat-size ( 'stat -> 'stat-size )`
* `stat-type ( 'stat -> 'stat-type )`
* `stat-dev ( 'stat -> 'stat-dev )`
* `stat-qid ( 'stat -> 'stat-qid )`
* `stat-mode ( 'stat -> 'stat-mode )`
* `stat-atime ( 'stat -> 'stat-atime )`
* `stat-mtime ( 'stat -> 'stat-mtime )`
* `stat-length ( 'stat -> 'stat-length )`
* `stat-name ( 'stat -> 'stat-name )`
* `stat-uid ( 'stat -> 'stat-uid )`
* `stat-gid ( 'stat -> 'stat-gid )`
* `stat-muid ( 'stat -> 'stat-muid )`
* `stat-base% ( -> stat-alignment #stat )`: size of the constant-sized part of
`stat`; for use with gforth struct allocation routines
* `/stat-base ( -> #stat )`: size of the constant-sized part of `stat`


## Encoding and decoding

Routines encoding T- messages always return a buffer and length containing the
encoded message on the top of stack, i.e. their stack diagram has the form
`( ... -> ... buf #buf )`. On the other hand, all routines decoding R- messages
expect the message length on the top of stack, i.e. `( #msg -> ... )`.

A routine's name and stack diagram reflect its name and parameters as described
in [2]. Whenever there are less items in the stack diagram than in the
protocol documentation, 9p4 chooses sensible values for the missing parameters.


* ```Tversion ( -> buf #buf )```
* ```Rversion ( #msg -> version #version msize )```
* ```Tattach ( uname #uname aname #aname -> rootfid buf #buf )```
* ```Rattach ( #msg -> 'qid )```
* ```Twalk ( name #name ... #names fid -> newfid buf #buf )```
* ```clonefid ( fid -> newfid buf #buf )```: same as ```0 fid Twalk```
* ```Rwalk ( #msg -> 'qids #qids )```
* ```Topen ( fid mode -> buf #buf )```
* ```Ropen ( #msg -> 'qid iounit )```
* ```Tcreate ( fid name #name perm mode -> buf #buf )```
* ```Rcreate ( #msg -> 'qid iounit )```
* ```Tread ( fid offset count -> buf #buf )```
* ```Rread ( #msg -> data count )```
* ```Twrite ( fid offset data count -> buf #buf )```
* ```Rwrite ( #msg -> count )```
* ```Tclunk ( fid -> buf #buf )```
* ```Rclunk ( #msg -> )```
* ```Tremove ( fid -> buf #buf )```
* ```Rremove ( fid -> buf #buf )```
* ```Tstat ( fid -> buf #buf )```
* ```Rstat ( #msg -> 'stat len )```
* ```Twstat ( 'stat fid -> len )```
* ```Rwstat ( #msg -> )```


## References

[1] [gforth](https://gforth.org)

[2] [introduction to the Plan 9 File Protocol, 9P](https://man.9front.org/5/intro)

[3] [A sane distributed file system](https://9p.cat-v.org)

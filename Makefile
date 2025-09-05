CFLAGS=-ferror-limit=1 -std=c99 -Wpedantic -Wall -Wextra -Wno-string-plus-int -fsanitize=address,undefined,bounds
#CFLAGS=-std=c99 -Wpedantic -Wall -Wextra -g3 -Og

OBJECT=rax.o

all:token

token:token.c rax.o

token.rl:element.rl

token.c:token.rl element.h

element.h:element.m4
	m4 -D variant=c $< > $@

element.rl:element.m4
	m4 -D variant=ragel $< | sed "s/@aq@/'/g" > $@
# @aq@ is a quadrigraph. In groff, \(aq inserts a neutral apostrophe

RAW_RAX=https://raw.githubusercontent.com/antirez/rax/1927550cb218ec3c3dda8b39d82d1d019bf0476d

rax.h:
	curl $(RAW_RAX)/$@ > $@
rax.c:
	curl $(RAW_RAX)/$@ > $@
rax_malloc.h:
	curl $(RAW_RAX)/$@ > $@

rax.o:rax.c rax.h rax_malloc.h
	
clean:
	rm -f token token.c element.h element.rl

.SUFFIXES:.c .rl

.rl.c:
	ragel -G2 $<

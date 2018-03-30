all:	platoterm128.d64 doc
.phony:	all vice doc

vice:	platoterm128.d64
	x128 platoterm128.d64

# Look for cc65:
# 1. when you've set the envvar CC65_HOME, trust it
# 2. when it's on your path, use that
# 3. hope it's in /opt/cc65 if all else fails
ifndef CC65_HOME
CC65_WHICH := $(shell which cc65 2>/dev/null)
ifndef CC65_WHICH
CC65_HOME := $(shell dirname $(CC65_WHICH) )
else
CC65_HOME := /opt/cc65
endif
endif

CC = $(CC65_HOME)/bin/cl65
AS = $(CC65_HOME)/bin/ca65
CFLAGS = -C ../../build/c128.cfg -O


platoterm128.d64: \
	disc/platoterm128,prg \
	disc/plato-pen,prg
	c1541 -format platoterm\ c=128,pt d64 platoterm128.d64 \
		-attach platoterm128.d64 \
		-write platoterm123,prg \
		-write license copying,seq \
		-write doc/platoterm128.txt manual,seq

disc/platoterm128,prg: src/platoterm128.o
	cp src/platoterm128.o disc/platoterm128,prg

src/platoterm128.o:
	$(MAKE) -C src platoterm128.o

doc: doc/platoterm128.txt \
	doc/platoterm128.pdf

doc/platoterm128.txt:	doc/platoterm128.texi

doc/platoterm128.pdf:	doc/platoterm128.texi

doc/platoterm128.html.d:	doc/platoterm128.texi



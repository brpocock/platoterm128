all:	platoterm.d64

platoterm.d64: disc/test,prg
	c1541 -format platoterm128,pt d64 platoterm.d64 \
		-attach platoterm.d64 \
		-write test,prg

disc/test,prg:
	$(MAKE) -C src
	cp src/display/vdc.o disc/test,prg

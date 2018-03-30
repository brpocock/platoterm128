all:	platoterm128.o

platoterm128.o:	display/display.o protocol/protocol.o system/system.o system/loader.o control/keyboard.o net/serial.o


net/serial.o:
	$(MAKE) -C net serial.o

display/display.o:
	$(MAKE) -C display display.o

control/keyboard.o:
	$(MAKE) -C control keyboard.o

control/lightpen.o:
	$(MAKE) -C control lightpen.o

control/mouse1351.o:
	$(MAKE) -C control mouse1351.o

control/joystick.o:
	$(MAKE) -C control joystick.o

protocol/protocol.o:
	$(MAKE) -C protocol protocol.o

system/system.o:
	$(MAKE) -C system system.o

system/loader.o:
	$(MAKE) -C system loader.o


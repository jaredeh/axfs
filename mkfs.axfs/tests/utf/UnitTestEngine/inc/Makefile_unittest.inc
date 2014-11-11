CFILEROOT = ${abspath ../../}
UTEROOT   = ${abspath ../../../../UnitTestEngine}
SRCROOT   = ${abspath ../../../../../../src}
RBROOT    = ${abspath ../../../../../../libs/rb_tree}
SQROOT    = ${abspath ../../../../../../libs/squashfs_compressor}
YAMLROOT  = ${abspath ../../../../../../libs/yaml}
TOMROOT   = ${abspath ../../../../../../libs/libtomcrypt}

INC  = -I./inc -I${CFILEROOT}/inc -I${CFILEROOT}/src -I${UTEROOT}/inc -I${SRCROOT}
INC += -I${RBROOT}
INC += -I${YAMLROOT}/include
INC += -I${TOMROOT}/src/headers
LIBS  = -L ${RBROOT} -lrb_tree
LIBS += -L ${SQROOT} -lsquashfs_compressor
LIBS += -L ${TOMROOT} -ltomcrypt

CFLAGS = -fPIC -Wall -g -O2

ifeq ($(firstword $(shell uname -a)),Linux)
	#Extras required for GNUstep on Ubuntu not for Mac where I did most dev work
	INC += -I/usr/local/include/GNUstep
	INC += -I/usr/include/GNUstep
	LIBS += -L /usr/lib/GNUstep -lgnustep-base -lobjc -lm -lc
	CFLAGS += -MMD -MP -DGNUSTEP -DGNUSTEP_BASE_LIBRARY=1 -DGNU_GUI_LIBRARY=1 -DGNU_RUNTIME=1 -DGNUSTEP_BASE_LIBRARY=1 -fno-strict-aliasing -fexceptions -fobjc-exceptions -D_NATIVE_OBJC_EXCEPTIONS -DGSWARN -DGSDIAGNOSE -Wno-import -fgnu-runtime -fconstant-string-class=NSConstantString
else
	LIBS += -framework Foundation
endif

.SUFFIXES: .o .m
.m.o:

all:
	mkdir -p build
	mkdir -p ${UTEROOT}/build
	${CC} ${INC} -g -c ./src/stubs.c -o ./build/stubs.o
	${CC} ${CFLAGS} ${INC} -c ./src/unittests.m -o ./build/unittests.o
	${CC} ${INC} -g -c ${UTEROOT}/src/dummy_main.c -o ./build/main.o
	${CC} -o ./test ./build/main.o ./build/stubs.o ./build/unittests.o ${UTEROOT}/build/CuTest.o ${LIBS}

clean:
	rm -rf ./build/* ./lib*.* ./src/*~ 
	rm -rf ./inc/*~ ./Makefile~ ./test ./test.exe ./core

clobber: clean
	rm -rf ./src/function.c
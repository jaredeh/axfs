CFILEROOT = ${abspath ../../}
UTEROOT = ${abspath ../../../../UnitTestEngine}
SRCROOT = ${abspath ../../../../../../src}
RBROOT = ${abspath ../../../../../../rb_tree}

INC = -I./inc -I${CFILEROOT}/inc -I${CFILEROOT}/src -I${UTEROOT}/inc -I${SRCROOT} -I${RBROOT}
LIBS = -L ../../../../../../rb_tree -lrb_tree
LIBS += -L ../../../../../../squashfs_compressor -lsquashfs_compressor
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
	${CC} ${CFLAGS} ${INC} -c ./src/unittests.m -o ./build/unittests.o
	${CC} -o ./test ./build/unittests.o ${UTEROOT}/build/CuTest.o ${LIBS}

clean:
	rm -rf ./build/* ./lib*.* ./src/*~ 
	rm -rf ./inc/*~ ./Makefile~ ./test ./test.exe ./core

clobber: clean
	rm -rf ./src/function.c
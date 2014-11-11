CFILEROOT = ${abspath ../}
UTEROOT   = ${abspath ../../../../utf/UnitTestEngine}
SRCROOT   = ${abspath ../../../../../src}
RBROOT    = ${abspath ../../../../../libs/rb_tree}
SQROOT    = ${abspath ../../../../../libs/squashfs_compressor}
YAMLROOT  = ${abspath ../../../../../libs/yaml}
TOMROOT   = ${abspath ../../../../../libs/libtomcrypt}

INC  = -I./inc -I${CFILEROOT}/inc -I${CFILEROOT}/src -I${UTEROOT}/inc -I${SRCROOT}
INC += -I${RBROOT}
INC += -I${YAMLROOT}/include
INC += -I${TOMROOT}/src/headers
LIBS  = -L ${RBROOT} -lrb_tree
LIBS += -L ${SQROOT} -lsquashfs_compressor
LIBS += -L ${YAMLROOT}/src/.libs -lyaml
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

# use to confirm you have the appropriate headers and external stubs to
#  be able to compile the original source
all:
	${CC} ${CFLAGS} ${INC} -c ./compile_test.m -o ./compile_test.o
	${CC} ${INC} -c ./compile_test_stubs.m -o ./compile_test_stubs.o
	${CC} ./compile_test.o ./compile_test_stubs.o -o ./compile_test ${LIBS}

clean:
	rm -rf ./Makefile~ ./*.c~ ../inc/*.h~
	rm -rf ./*.o ./compile_test ./*.exe ./*.d
	rm -rf *~ ../inc/*~

clobber: clean
	rm -rf ./${CFILE}.c

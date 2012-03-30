CC = gcc
INC = -I../inc -I../../../UnitTestEngine/inc
INC += -I/home/jaredeh/GNUstep/Library/Headers
INC += -I/usr/local/include/GNUstep
INC += -I/usr/include/GNUstep
INC += -I../../../../../rb_tree
CFLAGS = -MMD -MP -DGNUSTEP -DGNUSTEP_BASE_LIBRARY=1 -DGNU_GUI_LIBRARY=1 -DGNU_RUNTIME=1 -DGNUSTEP_BASE_LIBRARY=1 -fno-strict-aliasing -fexceptions -fobjc-exceptions -D_NATIVE_OBJC_EXCEPTIONS -fPIC -Wall -DGSWARN -DGSDIAGNOSE -Wno-import -g -O2 -fgnu-runtime -fconstant-string-class=NSConstantString
LIBS = -L /usr/lib/GNUstep -L ../../../../../rb_tree -lgnustep-base -lobjc -lm -lc -lrb_tree

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

deepclean: clean
	rm -rf ./${CFILE}.c

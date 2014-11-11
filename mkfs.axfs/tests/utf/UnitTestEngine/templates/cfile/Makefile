CC = gcc
INC = -I../inc -I../../../UnitTestEngine/inc
CFLAGS = -g -Wall

# use to confirm you have the appropriate headers and external stubs to
#  be able to compile the original source
all:
	${CC} ${CFLAGS} ${INC} -c ./compile_test.c -o ./compile_test.o
	${CC} ${CFLAGS} ${INC} -c ./compile_test_stubs.c -o ./compile_test_stubs.o
	${CC} ${CFLAGS} ./compile_test.o ./compile_test_stubs.o -o ./compile_test

clean:
	rm -rf ./Makefile~ ./*.c~ ../inc/*.h~
	rm -rf ./*.o ./compile_test ./*.exe

deepclean: clean
	rm -rf ./${CFILE}

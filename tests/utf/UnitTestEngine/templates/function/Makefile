CFILEROOT = ../../
UTEROOT = ../../../../UnitTestEngine

INC = -I./inc -I${CFILEROOT}inc -I${UTEROOT}/inc

all:
	${CC} ${INC} -g -c ./src/stubs.c -o ./build/stubs.o
	${CC} ${INC} -g -c ./src/unittests.c -o ./build/unittests.o
	${CC} ${INC} -g -c ${UTEROOT}/src/dummy_main.c -o ./build/main.o
	${CC} -g -o ./test ./build/main.o ./build/stubs.o ./build/unittests.o ${UTEROOT}/build/CuTest.o

clean:
	rm -rf ./build/* ./lib*.* ./src/*.c~ 
	rm -rf ./inc/*.h~ ./Makefile~ ./test ./test.exe ./core

deepclean: clean
	rm -rf ./src/function.c

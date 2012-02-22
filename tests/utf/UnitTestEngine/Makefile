CFLAGS = -g
INC = -I./inc

all:
	${CC} ${INC} ${CFLAGS} -c ./src/CuTest.c -o ./build/CuTest.o
	${CC} ${INC} ${CFLAGS} -c ./src/runtest.c -o ./build/runtest.o
	${CC} ./build/runtest.o ./build/CuTest.o -o ../runtest
	
clean:
	rm -rf ../runtest ../runtest.* ./build/* 
	rm -rf ./src/*.c~ ./inc/*.h~ ./Makefile~

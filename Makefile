OBJ = src/falloc.o src/data_object.o src/dir_walker.o src/main.o

INC= -I /usr/include/GNUstep
LIBS = -L /usr/lib/GNUstep -L rb_tree
LIBS += -lgnustep-base -lobjc -lm -lc -lrb_tree
CFLAGS = -fconstant-string-class=NSConstantString -D_NATIVE_OBJC_EXCEPTIONS

%.o: %.c
	gcc $(INC) $(CFLAGS) $(LIBS) -c -o $@ $<

%.o: %.m
	gcc $(INC) $(CFLAGS) $(LIBS) -c -o $@ $<

all: $(OBJ)
	gcc  $(INC) $(CFLAGS) $(LIBS) -o thing $(OBJ)

mac: $(OBJ)
	gcc -o thing $(OBJ) -framework Foundation

clean:
	rm -f src/*.o
	rm -f src/*~
	rm -f thing



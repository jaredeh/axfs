
TOOL_NAME = mkfs.axfs
mkfs.axfs_OBJC_FILES = src/falloc.m \
                       src/data_object.m \
                       src/dir_walker.m \
                       src/main.m

ifeq ($(firstword $(shell uname -a)),Linux)

GNUSTEP_MAKEFILES=/usr/share/GNUstep/Makefiles/
include $(GNUSTEP_MAKEFILES)/common.make
include $(GNUSTEP_MAKEFILES)/tool.make

else

OBJ = $(subst .m,.o,$(mkfs.axfs_OBJC_FILES))
LIBS = -L rb_tree

%.o: %.m
	gcc $(INC) $(CFLAGS) $(LIBS) -c -o $@ $<

all: $(OBJ)
	gcc -o $(TOOL_NAME) $(OBJ) -framework Foundation

endif

clean::
	rm -f src/*.o
	rm -f src/*~
	-$(MAKE) -C squashfs_compressor clean
	-$(MAKE) -C rb_tree clean
	rm -f mkfs.axfs

clobber: clean
	-$(MAKE) -C squashfs_compressor clobber
	-$(MAKE) -C rb_tree clobber

configure:
	$(MAKE) -C squashfs_compressor configure

lib:
	$(MAKE) -C rb_tree lib
	$(MAKE) -C squashfs_compressor lib

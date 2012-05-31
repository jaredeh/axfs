
TOOL_NAME = mkfs.axfs
mkfs.axfs_OBJC_FILES = src/bytetable.m \
                       src/compressor.m \
                       src/data_object.m \
                       src/dir_walker.m \
                       src/falloc.m \
                       src/getopts.m \
                       src/main.m \
                       src/nodes.m \
                       src/pages.m \
                       src/region.m \
                       src/strings.m \
                       src/super.m

INC = -I rb_tree/
LIBDIRS = -L rb_tree -L squashfs_compressor 
LIBS = -l rb_tree -l squashfs_compressor

ifeq ($(firstword $(shell uname -a)),Linux)

GNUSTEP_MAKEFILES=/usr/share/GNUstep/Makefiles/
include $(GNUSTEP_MAKEFILES)/common.make
include $(GNUSTEP_MAKEFILES)/tool.make

ADDITIONAL_INCLUDE_DIRS = $(INC)
ADDITIONAL_LIB_DIRS = $(LIBDIRS)
ADDITIONAL_TOOL_LIBS = $(LIBS)

else

OBJ = $(subst .m,.o,$(mkfs.axfs_OBJC_FILES))

%.o: %.m
	$(CC) $(INC) $(CFLAGS) -c -o $@ $<

all: $(OBJ)
	$(CC) -o $(TOOL_NAME) $(OBJ) $(LIBDIRS) $(LIBS) -framework Foundation

endif

clean::
	rm -f src/*.o
	rm -f src/*~
	rm -f mkfs.axfs

clobber: clean
	-$(MAKE) -C squashfs_compressor clobber
	-$(MAKE) -C rb_tree clobber

configure:
	$(MAKE) -C squashfs_compressor configure

lib:
	$(MAKE) -C rb_tree lib
	$(MAKE) -C squashfs_compressor lib



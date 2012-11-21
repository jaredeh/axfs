
TOOL_NAME = mkfs.axfs
mkfs.axfs_OBJC_FILES = bytetable.m \
                       compressor.m \
                       dir_walker.m \
                       falloc.m \
                       getopts.m \
                       image_builder.m \
                       main.m \
                       nodes.m \
                       modes.m \
                       inodes.m \
                       opts_validator.m \
                       pages.m \
                       region.m \
                       strings.m \
                       super.m \
                       c_blocks.m

INC = -I ../libs/rb_tree/
LIBDIRS = -L ../libs/rb_tree -L ../libs/squashfs_compressor 
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
	rm -f *.o
	rm -f *~
	rm -f mkfs.axfs

clobber: clean




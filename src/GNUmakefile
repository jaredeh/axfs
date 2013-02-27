
TOOL_NAME = mkfs.axfs
mkfs.axfs_OBJC_FILES = astrings.m \
                       axfs_helper.m \
                       btree_object.m \
                       bytetable.m \
                       c_blocks.m \
                       compressible_object.m \
                       compressor.m \
                       dir_walker.m \
                       falloc.m \
                       getopts.m \
                       image_builder.m \
                       inodes.m \
                       main.m \
                       modes.m \
                       nodes.m \
                       nodes_object.m \
                       ba_nodes.m \
                       comp_nodes.m \
                       xip_nodes.m \
                       region_descriptors.m \
                       opts_validator.m \
                       pages.m \
                       region.m \
                       super.m

INC = -I ../libs/rb_tree/ -I ../libs/libtomcrypt/src/headers/ -I ./
LIBDIRS = -L ../libs/rb_tree -L ../libs/squashfs_compressor -L ../libs/libtomcrypt
LIBS = -l rb_tree -l squashfs_compressor -l tomcrypt
CFLAGS = -g
ifeq ($(firstword $(shell uname -a)),Linux)

GNUSTEP_MAKEFILES=/usr/share/GNUstep/Makefiles/
include $(GNUSTEP_MAKEFILES)/common.make
include $(GNUSTEP_MAKEFILES)/tool.make

ADDITIONAL_INCLUDE_DIRS = $(INC)
ADDITIONAL_LIB_DIRS = $(LIBDIRS)
ADDITIONAL_TOOL_LIBS = $(LIBS)

mv obj/$(TOOL_NAME) ../

else

OBJ = $(subst .m,.o,$(mkfs.axfs_OBJC_FILES))

%.o: %.m
	$(CC) $(INC) $(CFLAGS) -c -o $@ $<

all: $(OBJ)
	$(CC) $(CFLAGS) -o $(TOOL_NAME) $(OBJ) $(LIBDIRS) $(LIBS) -framework Foundation
	mv $(TOOL_NAME) ../

endif

clean::
	rm -f *.o
	rm -f *~
	rm -f ../mkfs.axfs
	rm -rf obj

clobber: clean




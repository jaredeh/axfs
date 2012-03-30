GNUSTEP_MAKEFILES=/usr/share/GNUstep/Makefiles/

include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = mkfs.axfs
mkfs.axfs_OBJC_FILES = src/falloc.m \
                       src/data_object.m \
                       src/dir_walker.m \
                       src/main.m

include $(GNUSTEP_MAKEFILES)/tool.make

clean::
	rm -f src/*.o
	rm -f src/*~

clobber: clean
	-$(MAKE) -C squashfs_compressor clobber
	-$(MAKE) -C rb_tree clobber

configure:
	$(MAKE) -C squashfs_compressor configure

lib: configure
	$(MAKE) -C squashfs_compressor lib
	$(MAKE) -C rb_tree lib

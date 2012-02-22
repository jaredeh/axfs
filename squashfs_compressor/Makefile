OBJS = compressor.o gzip_wrapper.o lzo_wrapper.o lzma_xz_wrapper.o xz_wrapper.o 

CC = gcc

CFLAGS = -g \
         -DGZIP_SUPPORT=1 \
         -DLZO_SUPPORT=1 \
         -DXZ_SUPPORT=1 \
         -DLZMA_SUPPORT=1

COMPLIBS = ./zlib-1.2.6/libz.a \
           ./lzo-2.06/src/.libs/liblzo2.a \
           ./xz-5.0.3/src/liblzma/.libs/liblzma.a

./xz-5.0.3/src/liblzma/.libs/liblzma.a:
	$(MAKE) -C ./xz-5.0.3

./zlib-1.2.6/libz.a:
	$(MAKE) -C ./zlib-1.2.6 libz.a

./lzo-2.06/src/.libs/liblzo2.a:
	$(MAKE) -C ./lzo-2.06

lib: $(OBJS) $(COMPLIBS)
	ar rcsT libsquashfs_compressor.a $(OBJS)
	ar rcsT libsquashfs_compressor.a $(COMPLIBS)

compile_test: $(OBJS) test_compressor.o lib
	gcc -static $(LIBS) -o run_me $(OBJS) test_compressor.o libsquashfs_compressor.a

clean:
	$(MAKE) -C ./lzo-2.06 clean
	$(MAKE) -C ./xz-5.0.3 clean
	$(MAKE) -C ./zlib-1.2.6 clean
	rm -rf *.o *~
	rm -rf run_me

clobber: clean
	$(MAKE) -C ./lzo-2.06 distclean
	$(MAKE) -C ./xz-5.0.3 distclean
	$(MAKE) -C ./zlib-1.2.6 distclean
	rm -rf libsquashfs_compressor.a

configure:
	cd lzo-2.06; ./configure; cd ../
	cd zlib-1.2.6; ./configure; cd ../
	cd xz-5.0.3; ./configure; cd ../



#install liblzma-dev liblzo2-dev

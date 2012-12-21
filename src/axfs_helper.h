#import <Foundation/Foundation.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#ifdef __MACH__
#include <mach/mach.h>
#endif

struct data_struct {
	void *data;
	uint64_t place;
	uint64_t total;
	uint64_t used;
};

struct axfs_config {
	char *input;
	char *output;
	char *secondary_output;
	char *compression;
	uint64_t page_size;
	char *page_size_str;
	uint64_t block_size;
	char *block_size_str;
	uint64_t xip_size;
	char *xip_size_str;
	char *profile;
	char *special;
	uint64_t mmap_size;
	uint64_t max_nodes;
	uint64_t max_text_size;
	uint64_t max_number_files;
	uint64_t max_filedata_size;
	uint64_t real_number_files;
	uint64_t real_number_nodes;
	uint64_t real_imagesize;
	uint8_t version_major;
	uint8_t version_minor;
	uint8_t version_sub;
};

#define AXFS_DEFAULT__PAGE_SIZE 4096
#define AXFS_DEFAULT__BLOCK_SIZE 4096


@interface NSObject (axfs)
-(uint64_t) alignNumber: (uint64_t) number bytes: (uint64_t) d;
-(uint8_t) outputByte: (uint64_t) datum byte: (uint8_t) i;
-(uint8_t *) outputDatum: (uint64_t) datum depth: (uint8_t) depth buffer: (uint8_t *) buffer;
-(uint8_t *) bigEndianize: (uint64_t) number ptr: (void *) ptr bytes: (int) j;
-(uint8_t *) bigEndian64: (uint64_t) number ptr: (void *) ptr;
-(uint8_t *) bigEndian32: (uint32_t) number ptr: (void *) ptr;
-(uint8_t *) bigEndian16: (uint16_t) number ptr: (void *) ptr;
-(uint8_t *) bigEndianByte: (uint8_t) number ptr: (void *) ptr;
@end
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#ifdef __MACH__
#include <mach/mach.h>
#endif

struct data_struct {
	void *data;
	uint64_t place;
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
	uint64_t max_nodes;
	uint64_t max_text_size;
	uint64_t max_number_files;
	uint64_t max_filedata_size;
};

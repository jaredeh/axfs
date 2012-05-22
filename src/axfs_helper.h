#include <stdio.h>
#include <stdlib.h>
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
	uint64_t block_size;
	uint64_t xip_size;
	char *profile;
	char *special;
};

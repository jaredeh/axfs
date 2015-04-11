
#include <string.h>
#include <stdlib.h>

#include "squashfs_fs.h"
#include "compressor.h"

static int null_compress(void *strm, void *d, void *s, int size, int block_size,
		int *error)
{
	memcpy( d, s, size);
	return size;
}


static int null_uncompress(void *d, void *s, int size, int block_size, int *error)
{
	memcpy(d, s, size);
	return size;
}


struct compressor null_comp_ops = {
	.init = NULL,
	.compress = null_compress,
	.uncompress = null_uncompress,
	.options = NULL,
	.usage = NULL,
	.id = NULL_COMPRESSION,
	.name = "null",
	.supported = 1
};


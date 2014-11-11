/* pages.m.c has no main(). I add it here to allow us to link it */
#include "pre.h" // external types declarations, such as u32 or Linux struct bio;

/* actual files to compile test */
#include "../../../../../src/xip_nodes.m"

/* too lazy to build this junk seperately. */
#include "../../../../../src/c_blocks.m"
#include "../../../../../src/compressor.m"
#include "../../../../../src/compressible_object.m"
#include "../../../../../src/btree_object.m"
#include "../../../../../src/bytetable.m"
#include "../../../../../src/region.m"
#include "../../../../../src/nodes_object.m"

struct axfs_config acfg;

int main(int argc, char * argv[])
{
	return 0;
}


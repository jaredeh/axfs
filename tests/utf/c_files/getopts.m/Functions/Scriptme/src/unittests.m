#import <Foundation/Foundation.h>
#import "getopts.h"
#import "getopts.m"
#import <Foundation/NSAutoreleasePool.h>

struct axfs_config acfg;

int main( int argc, const char *argv[] ) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	GetOpts *go;

	go = [[GetOpts alloc] init];
	[go argc: argc argv: (char **) argv];

	[pool drain];

	if (argc == 1)
		return 0;

	printf("---\n");
	printf("axfs_config:\n");
	printf("\tinput:\t%s\n",acfg.input);
	printf("\tsecondary_output:\t%s\n",acfg.secondary_output);
	printf("\toutput:\t%s\n",acfg.output);
	printf("\tcompression:\t%s\n",acfg.compression);
	printf("\tprofile:\t%s\n",acfg.profile);
	printf("\tspecial:\t%s\n",acfg.special);
	printf("\txip_size:\t%llu\n",acfg.xip_size);
	printf("\tblock_size:\t%llu\n",acfg.block_size);
	return 0;
}
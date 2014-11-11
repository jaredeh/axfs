#import <Foundation/Foundation.h>
#import "getopts.h"
#import "getopts.m"
#import <Foundation/NSAutoreleasePool.h>

struct axfs_config acfg;

char * denullify(char * foo) {
	return foo == NULL ? "" : foo;
}

int main( int argc, const char *argv[] ) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	GetOpts *go;

	go = [[GetOpts alloc] init];
	[go argc: argc argv: (char **) argv];
	[go free];
	[go release];

	[pool drain];

	if (argc < 2)
		return 0;

	printf("---\n");
	printf("axfs_config:\n");
	printf("  input: %s\n",denullify(acfg.input));
	printf("  secondary_output: %s\n",denullify(acfg.secondary_output));
	printf("  output: %s\n",denullify(acfg.output));
	printf("  compression: %s\n",denullify(acfg.compression));
	printf("  profile: %s\n",denullify(acfg.profile));
	printf("  special: %s\n",denullify(acfg.special));
	printf("  page_size: %llu\n",(long long unsigned int)acfg.page_size);
	printf("  xip_size: %llu\n",(long long unsigned int)acfg.xip_size);
	printf("  block_size: %llu\n",(long long unsigned int)acfg.block_size);
	return 0;
}
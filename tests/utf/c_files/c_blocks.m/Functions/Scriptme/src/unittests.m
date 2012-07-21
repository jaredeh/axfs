#import <Foundation/Foundation.h>
#import "c_blocks.h"
#import "c_blocks.m"
#import <Foundation/NSAutoreleasePool.h>
#include <yaml.h>

struct axfs_config acfg;

char * denullify(char * foo) {
	return foo == NULL ? "" : foo;
}

int main( int argc, const char *argv[] ) {
	while (true) {

	}
}

/*
int main( int argc, const char *argv[] ) {	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CBlocks *cb;
	GetOpts *go;
	bool retval = true;
	char *msg;

	if (argc < 2)
		return 0;
	
	go = [[GetOpts alloc] init];
	[go initialize]; 
	[go argc: argc argv: (char **) argv];

	cb = [[CBlocks alloc] init];

	[cb initialize];
	[cb free];
	[cb release];

	msg = malloc(1024);
	memset(msg,0,1024);
	memset(&acfg,0,sizeof(acfg));

	[pool drain];

	printf("---\n");
	printf("axfs_config:\n");
	printf("  input: %s\n",denullify(acfg.input));
	printf("  secondary_output: %s\n",denullify(acfg.secondary_output));
	printf("  output: %s\n",denullify(acfg.output));
	printf("  compression: %s\n",denullify(acfg.compression));
	printf("  profile: %s\n",denullify(acfg.profile));
	printf("  special: %s\n",denullify(acfg.special));
	printf("  xip_size: %llu\n",acfg.xip_size);
	printf("  block_size: %llu\n",acfg.block_size);
	printf("opts_validator:\n");
	printf("  valid: %s\n", retval ? "true":"false");
	printf("  msg: \"%s\"\n",denullify(msg));
	free(msg);

	return 0;
}
*/
#import <Foundation/Foundation.h>
#import "axfs_helper.h"
#import "getopts.h"
#import "opts_validator.h"

#import "dir_walker.h"
#import "data_object.h"
#import "falloc.h"
#import <Foundation/NSAutoreleasePool.h>

struct axfs_config acfg;

void do_getopts(int argc, const char *argv[]) {
	GetOpts *go;
	NSAutoreleasePool *pool;

	pool = [[NSAutoreleasePool alloc] init];
	go = [[GetOpts alloc] init];
	[go initialize];
	[go argc: argc argv: (char **) argv];
	[go free];
	[go release];
	[pool drain];
}

int do_opts_validation(void) {
	OptsValidator *ov;
	NSAutoreleasePool *pool;
	int retval;

	ov = [[OptsValidator alloc] init];
	[ov initialize];
	retval = [ov validate];
	[ov free];
	[ov release];
	pool = [[NSAutoreleasePool alloc] init];
	[pool drain];
	return retval;
}

int main(int argc, const char *argv[]) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	do_getopts(argc, argv);
	do_opts_validation();
	

	[pool drain];
	return 0;
}

/*
    AxfsDirWalker *dw;
	AxfsDataObject *ado;
	falloc *f;
	char *data;
	
	ado = [[AxfsDataObject alloc] init];
	
	f = [[falloc alloc] init];
	data = (char *) [f allocSize: 1024 path: "foo"];
	if (*data == -1)
		return 1;
	*data++ = 0x30;
	*data = 0x31;
	[f free];
	dw = [[AxfsDirWalker alloc] init];
	[dw setDataObject: ado];
	[dw walk: @"/usr/"];

	[ado printstats];
	
	[pool drain];
	return 0;
}
*/
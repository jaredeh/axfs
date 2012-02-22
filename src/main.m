#import <Foundation/Foundation.h>
#import "dir_walker.h"
#import "data_object.h"
#import "falloc.h"
#import <Foundation/NSAutoreleasePool.h>

int main( int argc, const char *argv[] ) {    
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
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

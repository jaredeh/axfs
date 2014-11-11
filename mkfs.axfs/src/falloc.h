#import "axfs_helper.h"
#import <Foundation/Foundation.h>

@interface falloc: NSObject {
	char * path;
	uint64_t size;
	void *data;
	int fd;
}
-(void *) allocSize: (uint64_t) allocsize path: (char *) pathname;
-(void) initialize;
-(void) free;
@end

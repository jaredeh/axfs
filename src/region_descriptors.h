#import <Foundation/Foundation.h>
#import "axfs_helper.h"
#import "axfs_objects.h"
#import "region.h"
#include "linux/axfs_ducttape.h"
#include "linux/axfs_fs.h"

extern struct axfs_config acfg;
extern struct axfs_objects aobj;

@interface NSObject(RegDescMethods)
-(Region *) region;
@end

@interface RegionDescriptors: NSObject {
	void *data;
	uint8_t *data_p;
	uint64_t fsoffset;
	uint64_t fsalign;
	uint64_t fspadding;
	uint64_t size;
}
-(void) fsalign: (uint64_t) align;
-(void) fsoffset: (uint64_t) offset;
-(uint64_t) fsoffset;
-(uint64_t) regionOffsets;
-(uint64_t) size;
-(void *) data;
-(void) free;

@end
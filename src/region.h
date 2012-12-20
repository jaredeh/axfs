#import <Foundation/Foundation.h>
#import "axfs_helper.h"

#define AXFS_REGION_SIZE (8*4+1+1)

@interface NSObject(RegionMethods)
-(uint64_t) size;
-(uint64_t) csize;
-(uint64_t) length;
-(uint64_t) fsoffset;
-(uint8_t) depth;
@end

@interface Region: NSObject {
	uint64_t size;
	void *data;
	uint8_t *data_p;
	uint64_t fsoffset;
	uint8_t incore;
	id o;
}

-(void) add: (id) oobj;
-(uint8_t *) data_p;
-(void *) data;
-(void) fsoffset: (uint64_t) offset;
-(uint64_t) fsoffset;
-(void) incore: (uint8_t) core;
-(uint64_t) size;
-(void) free;
@end


#import <Foundation/Foundation.h>
#import "axfs_helper.h"
#import "region.h"

extern struct axfs_config acfg;

@interface BtreeObject: NSObject {
	int (*CompFuncType)(const void *x, const void *y);
	Region *region;
	uint64_t fsoffset;
	uint64_t fsalign;
	uint64_t fspadding;
	struct data_struct hashablestruct;
	void **hashtable;
	uint64_t hashlen;
	bool deduped;
}
-(void *) allocData: (struct data_struct *) ds chunksize: (uint64_t) chunksize;
-(void) configureDataStruct: (struct data_struct *) ds length: (uint64_t) len;
-(uint8_t) depth;
-(Region *) region;
-(void) fsalign: (uint64_t) align;
-(void) fsoffset: (uint64_t) offset;
-(uint64_t) fsoffset;
-(void) free;
@end

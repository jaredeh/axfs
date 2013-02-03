#import <Foundation/Foundation.h>
#import "red_black_tree.h"
#import "axfs_helper.h"
#import "compressor.h"
#import "compressible_object.h"
#import "region.h"

#define AXFS_BYTETABLE_HASHTABLE_SIZE 65535

struct bytetable_value {
	uint64_t datum;
	uint64_t index;
	struct bytetable_value *next;
};

@interface ByteTable: CompressibleObject {
	uint8_t depth;
	uint64_t length;
	struct data_struct bytetable;
}
-(void) checkDepth: (uint64_t) datum depth: (uint8_t *) depth;
-(struct bytetable_value *) allocByteTableValue;
-(void) numberEntries: (uint64_t) entries dedup: (bool) dedup;
-(uint64_t) length;
-(uint64_t) size;
-(void *) add: (uint64_t) datum;
-(void *) index: (uint64_t) index datum: (uint64_t) datum;
-(void *) data;
-(uint8_t) depth;
-(void) free;
@end

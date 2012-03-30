#import <Foundation/NSObject.h>
#import "red_black_tree.h"
#import "axfs_helper.h"
#import "compressor.h"

struct bytetable_value {
	uint64_t datum;
	rb_red_blk_node rb_node;
};

@interface ByteTable: NSObject {
	uint8_t depth;
	uint64_t length;
	rb_red_blk_tree *tree;
	struct data_struct bytetable;
	uint8_t *dbuffer;
	uint8_t *cbuffer;
	bool deduped;
	uint64_t csize_cached;
}
-(void) numberEntries: (uint64_t) entries dedup: (bool) dedup;
-(uint64_t) length;
-(uint64_t) size;
-(void *) add: (uint64_t) datum;
-(void *) data;
-(void *) cdata;
-(uint64_t) csize;
-(uint8_t) depth;
-(void) free;
@end

#import <Foundation/NSObject.h>
#import "red_black_tree.h"

struct bytetable_value {
	uint64_t datum;
	rb_red_blk_node rb_node;
};

struct data_struct {
	void *data;
	uint64_t place;
};

@interface ByteTable: NSObject {
	uint8_t depth;
	uint64_t len;
	rb_red_blk_tree *tree;
	struct data_struct bytetable;
	uint8_t *dbuffer;
	bool deduped;
}
-(void) numberEntries: (uint64_t) entries dedup: (bool) dedup;
-(uint64_t) length;
-(uint64_t) size;
-(void *) add: (uint64_t) datum;
-(void *) data;
-(void) free;
@end

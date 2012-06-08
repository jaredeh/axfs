#import <Foundation/Foundation.h>
#import "red_black_tree.h"
#import "axfs_helper.h"
#import "compressor.h"

struct string_struct {
	void *data;
	uint64_t length;
	rb_red_blk_node rb_node;
};

@interface Strings: NSObject {
	struct data_struct strings;
	struct data_struct data;
	uint64_t length;
	rb_red_blk_tree *tree;
	uint64_t csize;
	uint8_t *cbuffer;
}
-(void) numberInodes: (uint64_t) inodes length: (uint64_t) len path: (char *) pathname;
-(void) initialize;
-(void) free;
-(void *) addString: (void *) data_ptr length: (uint64_t) len;
-(void *) allocStringData: (uint64_t) len;
@end

#import <Foundation/NSObject.h>
#import "red_black_tree.h"
#import "axfs_helper.h"

struct page_struct {
	void *data;
	uint64_t length;
	void *cdata;
	uint64_t clength;
	rb_red_blk_node rb_node;
};

@interface Pages: NSObject {
	struct data_struct pages;
	struct data_struct data;
	struct data_struct cdata;
	uint64_t page_size;
	uint64_t length;
	rb_red_blk_tree *tree;
}
-(void) numberPages: (uint64_t) numpages path: (char *) pathname;
-(void) free;
-(void *) addPage: (void *) page_data length: (uint64_t) page_length;
@end

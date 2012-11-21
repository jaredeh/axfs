#import <Foundation/Foundation.h>
#import "red_black_tree.h"
#import "axfs_helper.h"

extern struct axfs_config acfg;

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
	uint64_t length;
	rb_red_blk_tree *tree;
}
-(struct page_struct *) allocPageStruct;
-(void *) allocPageData;
-(void *) allocPageCdata;
-(void) populate: (struct page_struct *) page data: (void *) data_ptr length: (uint64_t) len;
-(void) configureRBtree;
-(void) configureDataStruct: (struct data_struct *) ds length: (uint64_t) len;
-(void *) addPage: (void *) data_ptr length: (uint64_t) len;
-(void) free;
@end

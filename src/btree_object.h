#import <Foundation/Foundation.h>
#import "red_black_tree.h"
#import "axfs_helper.h"
#import "region.h"

extern struct axfs_config acfg;

typedef void (*InorderProcessFuncType)(void *);

@interface BtreeObject: NSObject {
	rb_red_blk_tree *tree;
	rb_red_blk_node *nild;
	rb_red_blk_node *root;
	int (*CompFunc) (const void*,const void*);
	void (*PrintFunc) (const void* a);
	Region *region;
	uint64_t fsoffset;
	uint64_t fsalign;
	uint64_t fspadding;
}
-(void *) allocData: (struct data_struct *) ds chunksize: (uint64_t) chunksize;
-(void) configureRBtree;
-(void) configureDataStruct: (struct data_struct *) ds length: (uint64_t) len;
-(void) inorderTree: (InorderProcessFuncType) p;
-(void) inorderTreeProcess: (rb_red_blk_node*) x processor: (InorderProcessFuncType) p;
-(uint8_t) depth;
-(Region *) region;
-(void) fsalign: (uint64_t) align;
-(void) fsoffset: (uint64_t) offset;
-(uint64_t) fsoffset;
-(void) free;
@end

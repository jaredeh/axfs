#import <Foundation/Foundation.h>
#import "red_black_tree.h"
#import "axfs_helper.h"

extern struct axfs_config acfg;

@interface BtreeObject: NSObject {
	rb_red_blk_tree *tree;
	int (*CompFunc) (const void*,const void*);
}
-(void *) allocData: (struct data_struct *) ds chunksize: (uint64_t) chunksize;
-(void) configureRBtree;
-(void) configureDataStruct: (struct data_struct *) ds length: (uint64_t) len;
-(void) free;
@end

#import <Foundation/Foundation.h>
#import "red_black_tree.h"
#import "axfs_helper.h"

extern struct axfs_config acfg;

struct paths_struct {
	struct inode_struct *inode;
	rb_red_blk_node rb_node;
};

@interface Paths: NSObject {
	struct data_struct data;
	rb_red_blk_tree *tree;
}

-(void) configureRBtree;
-(void) configureDataStruct: (struct data_struct *) ds length: (uint64_t) len;
-(void *) addPath: (struct inode_struct *) inode;
-(void *) findParentInodeByPath: (NSString *) path;
-(void) free;
@end

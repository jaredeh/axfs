#import <Foundation/Foundation.h>
#import "red_black_tree.h"
#import "axfs_helper.h"

extern struct axfs_config acfg;

struct paths_struct {
	struct inode_struct *inode;
	rb_red_blk_node rb_node;
};

@interface Paths: BtreeObject {
	struct data_struct data;
}

-(void *) addPath: (struct inode_struct *) inode;
-(void *) findParentInodeByPath: (NSString *) path;
-(void) free;
@end

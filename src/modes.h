#import <Foundation/Foundation.h>
#import "red_black_tree.h"
#import "axfs_helper.h"

extern struct axfs_config acfg;

struct mode_struct {
	uint32_t gid;
	uint32_t uid;
	uint16_t mode;
	rb_red_blk_node rb_node;
};

@interface Modes: NSObject {
	struct data_struct modes;
	rb_red_blk_tree *tree;
}

-(void) configureRBtree;
-(void) configureDataStruct: (struct data_struct *) ds length: (uint64_t) len;
-(void *) addMode: (NSDictionary *) attribs;
-(uint64_t) length;
-(void) free;
@end

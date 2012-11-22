#import <Foundation/Foundation.h>
#import "red_black_tree.h"
#import "btree_object.h"
#import "axfs_helper.h"

extern struct axfs_config acfg;

struct mode_struct {
	uint32_t gid;
	uint32_t uid;
	uint16_t mode;
	rb_red_blk_node rb_node;
};

@interface Modes: BtreeObject {
	struct data_struct modes;
}
-(void *) addMode: (NSDictionary *) attribs;
-(uint64_t) length;
-(void) free;
@end

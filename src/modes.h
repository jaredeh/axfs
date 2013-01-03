#import <Foundation/Foundation.h>
#import "red_black_tree.h"
#import "btree_object.h"
#import "axfs_helper.h"
#import "axfs_objects.h"
#import "bytetable.h"

extern struct axfs_config acfg;
extern struct axfs_objects aobj;

struct mode_struct {
	uint32_t gid;
	uint32_t uid;
	uint16_t mode;
	rb_red_blk_node rb_node;
};

@interface Modes: BtreeObject {
	struct data_struct modes;
	ByteTable *modesTable;
	ByteTable *uids;
	ByteTable *gids;
}
-(void *) addMode: (NSDictionary *) attribs;
-(uint64_t) length;
-(id) modesTable;
-(id) uids;
-(id) gids;
-(void *) data;
-(void) free;
@end

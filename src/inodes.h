#import <Foundation/Foundation.h>
#import "red_black_tree.h"
#import "axfs_helper.h"
#import "paths.h"
#import "modes.h"
#import "strings.h"

extern struct axfs_config acfg;

struct inode_struct {
	uint64_t size;
	struct mode_struct *mode;
	int is_dir;
	struct string_struct *name;
	NSString *path; //use to find parent dir to link into our entry_list then delete?
	struct inode_struct *next;
	struct entry_list *list; //inodes for dir, nodes for files
	uint64_t length; /* for dir: # of children; for file: # of node */
	rb_red_blk_node rb_node;
	void *data; //remove
};

@interface Inodes: NSObject {
	struct data_struct inodes;
	struct data_struct data;
	struct data_struct cdata;
	Paths *paths;
	Strings *strings;
	Modes *modes;
	uint64_t page_size;
	uint64_t length;
	rb_red_blk_tree *tree;
}

-(void) configureRBtree;
-(void) configureDataStruct: (struct data_struct *) ds length: (uint64_t) len;
-(void *) addInode: (NSString *) path;
-(void) free;
@end

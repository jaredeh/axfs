#import <Foundation/Foundation.h>
#import "red_black_tree.h"
#import "axfs_helper.h"
#import "btree_object.h"
#import "paths.h"
#import "modes.h"
#import "astrings.h"
#include <unistd.h>

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

@interface Inodes: BtreeObject {
	struct data_struct inodes;
	struct data_struct data;
	struct data_struct cdata;
	struct data_struct symlink;
	Paths *paths;
	Strings *strings;
	Modes *modes;
	uint64_t page_size;
	uint64_t length;
}

-(void *) addInode: (NSString *) path;
-(void) free;
@end

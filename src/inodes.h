#import <Foundation/Foundation.h>
#import "red_black_tree.h"
#import "axfs_helper.h"
#import "btree_object.h"
#import "paths.h"
#import "modes.h"
#import "astrings.h"
#include <unistd.h>

extern struct axfs_config acfg;

struct entry_list {
	struct inode_struct **inodes;
	struct node_struct **node;
	uint64_t length;
	uint64_t position;
};

struct inode_struct {
	uint64_t size;
	struct mode_struct *mode;
	int is_dir;
	struct string_struct *name;
	NSString *path; //use to find parent dir to link into our entry_list then delete?
	struct inode_struct *next;
	struct inode_struct *prev;
	struct entry_list list; //inodes for dir, nodes for files
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
	struct data_struct inode_list;
	struct data_struct node_list;
	Paths *paths;
	Strings *strings;
	Modes *modes;
	uint64_t page_size;
	uint64_t length;
	ByteTable *fileSizeIndex;
	ByteTable *nameOffset;
	ByteTable *numEntriescblockOffset;
	ByteTable *modeIndex;
	ByteTable *arrayIndex;
}

-(void *) addInode: (NSString *) path;
-(id) fileSizeIndex;
-(id) nameOffset;
-(id) numEntriescblockOffset;
-(id) modeIndex;
-(id) arrayIndex;
-(void) free;
@end

#import <Foundation/Foundation.h>
#import "axfs_helper.h"
#import "btree_object.h"
#import "paths.h"
#import "modes.h"
#import "astrings.h"
#include <unistd.h>

#define AXFS_INODES_HASHTABLE_SIZE 65535
#define AXFS_PATHS_HASHTABLE_SIZE 65535

extern struct axfs_config acfg;
extern struct axfs_objects aobj;

struct entry_list {
	struct inode_struct **inodes;
	uint64_t *nodes;
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
	//uint64_t length; /* for dir: # of children; for file: # of node */
	void *data; //remove
	bool processed;
	uint64_t position;
};

struct paths_struct {
	struct inode_struct *inode;
	struct paths_struct *next;
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
	uint64_t page_size;
	uint64_t length;
	uint64_t position;
	void **nameOrder;
	ByteTable *fileSizeIndex;
	ByteTable *nameOffset;
	ByteTable *numEntries;
	ByteTable *modeIndex;
	ByteTable *arrayIndex;
}

-(void *) addInode: (NSString *) path;
-(id) fileSizeIndex;
-(id) nameOffset;
-(id) numEntries;
-(id) modeIndex;
-(id) arrayIndex;
-(void *) data;
-(void) free;
@end

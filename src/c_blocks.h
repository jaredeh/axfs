#import <Foundation/Foundation.h>
#import "red_black_tree.h"
#import "pages.h"
#import "nodes.h"
#import "compressor.h"
#import "btree_object.h"

struct cblock_struct {
	uint64_t length;
	uint64_t offset;
	uint64_t csize;
	uint64_t num;
	struct cblock_struct *next;
	void *cdata;
	struct axfs_node *nodes;
	struct axfs_node *current_node;
};

@interface CBlocks: BtreeObject {
	struct cblock_struct *cblocks;
	struct cblock_struct *fullpages;
	struct cblock_struct *partpages;
	struct cblock_struct *fullpage_current;
	struct data_struct data;
	struct data_struct cdata;
	uint64_t place;
	void *cbbuffer;
	void *uncbuffer;
	Compressor * compressor;
}

-(struct cblock_struct *) allocateCBlockStructs;
-(void *) allocCdata: (uint64_t) s;
-(void) compressCBlock: (struct cblock_struct *) cblock;
-(void) addNodeToCBlock: (struct axfs_node *) node cblock: (struct cblock_struct *) cb;
-(void) addFullPageNode: (struct axfs_node *) node;
-(void) addPartPageNode: (struct axfs_node *) node;
-(void) addNode: (struct axfs_node *) node;
-(uint64_t) size;
-(uint64_t) length;
-(void *) data;
-(void) free;

@end

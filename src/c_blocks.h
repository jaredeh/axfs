#import <Foundation/Foundation.h>
#import "red_black_tree.h"
#import "pages.h"
#import "nodes.h"
#import "compressor.h"

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

@interface CBlocks: NSObject {
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

-(void) addNode: (struct axfs_node *) node;
-(void *) data;
-(uint64_t) size;
-(uint64_t) length;
-(void) initialize;
-(void) free;

@end

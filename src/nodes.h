#import <Foundation/Foundation.h>
#import "red_black_tree.h"
#import "pages.h"
#import "compressor.h"
#import "axfs_helper.h"

extern struct axfs_config acfg;

enum {
	TYPE_XIP,
	TYPE_BYTEALIGNED,
	TYPE_COMPRESS
};

struct axfs_node {
	struct page_struct *page;
	struct axfs_node *next;
	uint64_t cboffset;
};

@interface Nodes: CompressibleObject {
	uint64_t place;
	bool cached;
	int type;
	struct page_struct **pages;
	void *cblks;
	struct axfs_node *nodes;
}

-(uint64_t) addPage: (void *) page;
-(void *) data;
-(uint64_t) length;
-(void) setType: (int) t;
-(void) free;
@end


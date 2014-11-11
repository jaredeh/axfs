#import <Foundation/Foundation.h>
#import "red_black_tree.h"
#import "pages.h"
#import "compressor.h"
#import "axfs_helper.h"
#import "compressible_object.h"

extern struct axfs_config acfg;

struct axfs_node {
	struct page_struct *page;
	struct axfs_node *next;
	uint64_t cboffset;
};

@interface NodesObject: CompressibleObject {
	uint64_t place;
	bool cached;
	int type;
	struct page_struct **pages;
	struct axfs_node *nodes;
}

-(uint64_t) addPage: (void *) page;
-(void *) data;
-(uint64_t) length;
-(uint8_t) depth;
-(void) free;

@end


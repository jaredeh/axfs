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

@interface Nodes: NSObject {
	uint64_t place;
	bool cached;
	bool ccached;
	void *data;
	void *cdata;
	void *cdata_partials;
	uint64_t size;
	uint64_t csize;
	int type;
	struct page_struct **pages;
}

-(uint64_t) addPage: (void *) page;
-(void *) data;
-(uint64_t) size;
-(void *) cdata;
-(uint64_t) csize;
-(uint64_t) length;
-(void) initialize;
-(void) free;
@end


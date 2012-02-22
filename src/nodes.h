#import <Foundation/NSObject.h>
#import "red_black_tree.h"
#import "pages.h"
#import "compressor.h"

enum {
	TYPE_XIP,
	TYPE_BYTEALIGNED,
	TYPE_COMPRESS
};

@interface Nodes: NSObject {
	uint8_t type;
	Pages **pages;
	uint64_t place;
	bool cached;
	bool ccached;
	void *data;
	uint64_t size;
	void *cdata;
	uint64_t csize;
	uint64_t pagesize;
}

-(void) numberEntries: (uint64_t) e nodeType: (uint8_t) t;
-(void) pageSize: (uint64_t) ps;
-(uint64_t) addPage: (void *) page;
-(void *) data;
-(uint64_t) size;
-(void *) cdata;
-(uint64_t) csize;
-(uint64_t) length;
-(void) free;
@end


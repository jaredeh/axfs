#import "ba_nodes.h"

@implementation BaNodes

-(void *) data {
	uint64_t i;
	struct page_struct *page;
	uint8_t *bd = data;

	if(cached) {
		return data;
	}
	cached = true;
	if (cdata)
		free(cdata);
	size = 0;
	for(i=0;i<place;i++) {
		page = pages[i];
		memcpy(bd, page->data, page->length);
		size += page->length;
		bd += page->length;
		[banodeOffset add: bd-data];
	}
	return data;
}

-(id) banodeOffset {
	return banodeOffset;
}

-(id) init {
	if (!(self = [super init]))
		return self;
	banodeOffset = [[ByteTable alloc] init];
	[banodeOffset numberEntries: acfg.max_nodes dedup: false];
	return self;
}

-(void) free {
	[super free];
	free(data);
}

@end

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
	}
	return data;
}

-(id) banodeOffset {
	return banodeOffset;
}

-(id) init {
	if (!(self = [super init]))
		return self;

	return self;
}

-(void) free {
	[super free];
	free(data);
}

@end

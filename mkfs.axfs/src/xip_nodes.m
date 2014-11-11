#import "xip_nodes.h"

@implementation XipNodes

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
		memset(bd + page->length, 0, acfg.page_size - page->length);
		size += acfg.page_size;
		bd += acfg.page_size;
	}
	return data;
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

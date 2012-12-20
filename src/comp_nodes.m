#import "comp_nodes.h"

@implementation CompNodes

-(void *) data {
	uint64_t i;
	struct page_struct *page;

	if(cached) {
		return data;
	}

	cached = true;
	if (cdata)
		free(cdata);

	size = 0;
	for(i=0;i<place;i++) {
		page = pages[i];
		nodes[i].page = page;
		[cb addNode: &nodes[i]];
	}
	size = [cb size];
	data = [cb data];
	return data;
}

-(id) cnodeOffset {
	return cnodeOffset;
}

-(id) cnodeIndex {
	return cnodeIndex;
}

-(id) cblockOffset {
	return cblockOffset;
}

-(id) init {
	if (!(self = [super init]))
		return self;

	cb = [[CBlocks alloc] init];
	nodes = malloc(sizeof(*nodes)*acfg.max_nodes);
	memset(nodes,0,sizeof(*nodes)*acfg.max_nodes);
	cnodeOffset = [[ByteTable alloc] init];
	cnodeIndex = [[ByteTable alloc] init];
	cblockOffset = [[ByteTable alloc] init];

	return self;
}

-(void) free {
	[super free];
	free(data);
}

@end

#import "nodes_object.h"

@implementation NodesObject

-(uint64_t) addPage: (void *) page {
	pages[place] = (struct page_struct *) page;
	place += 1;
	cached = false;
	return place-1;
}

-(void *) data {
	return data;
}

-(uint64_t) length {
	return place;
}

-(uint8_t) depth {
	return 0;
}

-(id) init {
	if (!(self = [super init]))
		return self;

	if(acfg.max_nodes < 1) {
		[NSException raise: @"nodes" format: @"can have acfg.max_nodes < 1"];
	}
	pages = malloc(sizeof(*pages)*acfg.max_nodes);
	memset(pages,0,sizeof(*pages)*acfg.max_nodes);
	data = malloc(acfg.page_size*acfg.max_nodes);
	memset(data,0,acfg.page_size*acfg.max_nodes);
	return self;
}

-(void) free {
	[super free];
	free(pages);
	free(cdata);
}

@end

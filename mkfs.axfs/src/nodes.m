#import "nodes.h"

@implementation Nodes

-(bool) pageIsXip {
	return false;
}

-(uint64_t) addPage: (void *) page {
	struct page_struct *pg = (struct page_struct *) page;
	uint64_t index;
	uint8_t type;

//	printf("Nodes addPage {\n");

	if ([self pageIsXip]) {
//		printf("\tNodes addPage xip\n");
		type = XIP;
		index = [xip addPage: page];
	} else if (pg->clength < pg->length) {
//		printf("\tNodes addPage comp pg->clength=%i < pg->length=%i\n",pg->clength,pg->length);
		type = Compressed;
		index = [compressed addPage: page];
	} else {
//		printf("\tNodes addPage ba\n");
		type = Byte_Aligned;
		index = [byte_aligned addPage: page];
	}

	[node_index add: index];
	[node_type add: type];
//	printf("} Nodes addPage end\n");
	return [node_type length] - 1;
}

-(uint64_t) length {
	return [node_type length];
}

-(id) xip {
	return xip;
}

-(id) byte_aligned {
	return byte_aligned;
}

-(id) compressed {
	return compressed;
}

-(id) nodeType {
	return node_type;
}

-(id) nodeIndex {
	return node_index;
}

-(uint64_t) size {
	uint64_t size = [xip size];
	size += [byte_aligned size];
	size += [compressed size];

	return size;
}

-(uint64_t) csize {
	uint64_t csize = [xip csize];
	csize += [byte_aligned csize];
	csize += [compressed csize];

	return csize;
}

-(void *) data {
	[self size];
	[self csize];
	return 0;
}

-(void) free {
	[xip free];
	[byte_aligned free];
	[compressed free];
	[xip release];
	[byte_aligned release];
	[compressed release];
}

-(id) init {
	if (!(self = [super init]))
		return self;

	xip = [[XipNodes alloc] init];
	byte_aligned = [[BaNodes alloc] init];
	compressed = [[CompNodes alloc] init];
	node_type = [[ByteTable alloc] init];
	node_index = [[ByteTable alloc] init];
	[node_type numberEntries: acfg.max_nodes dedup: false];
	[node_index numberEntries: acfg.max_nodes dedup: false];
	current = 0;

	return self;
}

@end

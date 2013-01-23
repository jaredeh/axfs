#import "nodes.h"

@implementation Nodes

-(bool) pageIsXip {
	return false;
}

-(uint64_t) addPage: (void *) page {
	struct page_struct *pg = (struct page_struct *) page;
	uint64_t retval;
	uint8_t type;

	printf("Nodes addPage {\n");

	if ([self pageIsXip]) {
		printf("\tNodes addPage xip\n");
		type = XIP;
		retval = [xip addPage: page];
	} else if (pg->clength < pg->length) {
		printf("\tNodes addPage comp pg->clength=%i < pg->length=%i\n",pg->clength,pg->length);
		type = Compressed;
		retval = [compressed addPage: page];
	} else {
		printf("\tNodes addPage ba\n");
		type = Byte_Aligned;
		retval = [byte_aligned addPage: page];
	}

	[node_type add: type];
	[node_index add: retval];
	printf("} Nodes addPage end\n");
	return retval;
}

-(uint64_t) length {
	uint64_t len;
	len = [xip length];
	len += [compressed length];
	len += [byte_aligned length];
	return len;
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

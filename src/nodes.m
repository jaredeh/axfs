#import "nodes.h"
#import "c_blocks.h"

@implementation Nodes

-(uint64_t) addPage: (void *) page {
	pages[place] = (struct page_struct *) page;
	place += 1;
	cached = false;
	return place-1;
}

-(void *) data {
	uint64_t i;
	struct page_struct *page;
	uint8_t *bd = data;
	CBlocks *cb = (CBlocks *) cblks;

	if(cached) {
		return data;
	}
	cached = true;
	if (cdata)
		free(cdata);
	size = 0;
	for(i=0;i<place;i++) {
		page = pages[i];
		if (type == TYPE_XIP) {
			memcpy(bd, page->data, page->length);
			memset(bd + page->length, 0, acfg.page_size - page->length);
			size += acfg.page_size;
			bd += acfg.page_size;
		} else if (type == TYPE_BYTEALIGNED) {
			memcpy(bd, page->data, page->length);
			size += page->length;
			bd += page->length;
		} else if (type == TYPE_COMPRESS) {
			nodes[i].page = page;
			[cb addNode: &nodes[i]];
		}
	}
	if (type == TYPE_COMPRESS) {
		size = [cb size];
		data = [cb data];
	}
	return data;
}

-(uint64_t) length {
	return place;
}

-(void) initialize {
	if(acfg.max_nodes < 1) {
		printf("can have acfg.max_nodes < 1\n");
		exit(-1);
	}
	pages = malloc(sizeof(*pages)*acfg.max_nodes);
	memset(pages,0,sizeof(*pages)*acfg.max_nodes);
}

-(void) setType: (int) t {
	type = t;
	if(type == TYPE_COMPRESS) {
		CBlocks *cb;
		cb = [[CBlocks alloc] init];
		[cb initialize];
		cblks = (void *) cb;
		nodes = malloc(sizeof(*nodes)*acfg.max_nodes);
		memset(nodes,0,sizeof(*nodes)*acfg.max_nodes);
	} else {
		data = malloc(acfg.page_size*acfg.max_nodes);
		memset(data,0,acfg.page_size*acfg.max_nodes);
		cdata = malloc(acfg.page_size*acfg.max_nodes);
		memset(cdata,0,acfg.page_size*acfg.max_nodes);
	}
}

-(void) free {
	CBlocks *cb = (CBlocks *) cblks;
	free(pages);
	free(cdata);
	free(cdata_partials);
	if(type == TYPE_COMPRESS) {
		free(nodes);
		[cb free];
		[cb release];
	} else {
		free(data);
	}
}

@end

#import "nodes.h"
#import "c_blocks.h"

@implementation Nodes

-(uint64_t) addPage: (void *) page {
	pages[place] = (struct page_struct *) page;
	place += 1;
	cached = false;
	ccached = false;
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
	ccached = false;
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

-(uint64_t) size {
	if(!cached) {
		[self data];
	}
	return size;
}

-(void *) cdata {
	Compressor * compressor;
	void *d;
	uint64_t s;
	if(ccached)
		return cdata;
	compressor = [[Compressor alloc] init];
	[compressor initialize];
	[compressor algorithm: acfg.compression];
	d = [self data];
	s = [self size];
	[compressor cdata: cdata csize: &csize data: d size: s];
	[compressor free];
	[compressor release];
	ccached = true;
	return cdata;
}

-(uint64_t) csize {
	if(!ccached)
		[self cdata];
	return csize;
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


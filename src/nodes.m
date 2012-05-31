#import "nodes.h"

@implementation Nodes

-(void) numberEntries: (uint64_t) e nodeType: (uint8_t) t {
	type = t;
	place = 0;
	pages = malloc(sizeof(struct page_struct *)*e);
	data = malloc(pagesize*e);
	cdata = malloc(pagesize*e);
	if (type == TYPE_COMPRESS)
		cdata_partials = malloc(pagesize*e);
}

-(void) pageSize: (uint64_t) ps {
	pagesize = ps;
}

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

	if(cached)
		return data;
	cached = true;
	ccached = false;
	size = 0;
	for(i=0;i<place;i++) {
		page = pages[i];
		if (type == TYPE_XIP) {
			memcpy(bd, page->data, page->length);
			memset(bd + page->length, 0, pagesize - page->length);
			size += pagesize;
			bd += pagesize;
		} else if (type == TYPE_BYTEALIGNED) {
			memcpy(bd, page->data, page->length);
			size += page->length;
			bd += page->length;
		} else if (type == TYPE_COMPRESS) {
			
		}
	}
	return data;
}

-(uint64_t) size {
	if(!cached)
		[self data];
	if(type == TYPE_XIP)
		size = [self length] * pagesize;
	return size;
}

-(void *) cdata {
	Compressor * compressor;
	if(ccached)
		return cdata;
	compressor = [[Compressor alloc] init];
	[compressor initialize: "gzip"];
	[compressor cdata: cdata csize: &csize data: [self data] size: [self size]];
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

-(void) free {
	free(pages);
	free(data);
	free(cdata);
	free(cdata_partials);
}

@end


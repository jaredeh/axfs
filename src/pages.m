#import "pages.h"

static int PagesComp(const void* av, const void* bv)
{
	struct page_struct * a = (struct page_struct *)av;
	struct page_struct * b = (struct page_struct *)bv;
	void *adata = (void *)a->data;
	void *bdata = (void *)b->data;

	if( a->length > b->length )
		return 1;
	if( a->length < b->length )
		return -1;

	return memcmp(adata,bdata,a->length);
}

@implementation Pages

-(struct page_struct *) allocPageStruct {
	uint64_t d = sizeof(struct page_struct);
	return (struct page_struct *) [self allocData: &pages chunksize: d];
}

-(void *) allocPageData {
	return [self allocData: &data chunksize: acfg.page_size];
}

-(void *) allocPageCdata {
	return [self allocData: &cdata chunksize: acfg.page_size];
}

-(void) populate: (struct page_struct *) page data: (void *) data_ptr length: (uint64_t) len {
	page->data = [self allocPageData];
	page->length = len;
	memcpy(page->data, data_ptr, page->length);
	page->cdata = [self allocPageCdata];
	[compressor cdata: page->cdata csize: &page->clength data: page->data size: page->length];

	page->rb_node.key = (void *)page;
}

-(void *) addPage: (void *) data_ptr length: (uint64_t) len {
	struct page_struct temp;
	struct page_struct *new_page;
	rb_red_blk_node *rb_node;

	memset(&temp,0,sizeof(temp));
	temp.data = data_ptr;
	temp.length = len;
	rb_node = RBExactQuery(tree,(void *)&temp);
	if (rb_node)
		return rb_node->key;
	new_page = [self allocPageStruct];
	[self populate: new_page data: data_ptr length: len];
	rb_node = &new_page->rb_node;
	RBTreeInsert(rb_node,tree,(void *)new_page,0);

	return rb_node->key;
}

-(id) init {
	CompFunc = PagesComp;
	if (self = [super init]) {
		uint64_t len;
		len = sizeof(struct page_struct) * (acfg.max_nodes + 1);
		[self configureDataStruct: &pages length: len];
		[self configureDataStruct: &data length: acfg.page_size * acfg.max_nodes];
		[self configureDataStruct: &cdata length: acfg.page_size * acfg.max_nodes];
		compressor = [[Compressor alloc] init];
	} 
	return self;
}

-(void) free {
	[super free];
	free(pages.data);
	free(data.data);
	free(cdata.data);
	[compressor free];
	[compressor release];
}

@end

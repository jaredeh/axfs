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

static void PagesDest(void* a) {;}

static void PagesPrint(const void* a) {
	printf("%i",*(int*)a);
}

static void PagesInfoPrint(void* a) {;}

static void PagesInfoDest(void *a){;}

@implementation Pages

-(struct page_struct *) allocPageStruct {
	struct page_struct *retval;
	struct page_struct *page_list = (struct page_struct *) pages.data;
	retval = &page_list[pages.place];
	pages.place += 1;
	return retval;
}

-(void *) allocPageData {
	void *retval;
	uint8_t *buffer = (uint8_t *) data.data;
	retval = &buffer[data.place];
	data.place += page_size;
	return retval;
}

-(void *) allocPageCdata {
	void *retval;
	uint8_t *buffer = (uint8_t *) cdata.data;
	retval = &buffer[cdata.place];
	cdata.place += page_size;
	return retval;
}

-(void) populate: (struct page_struct *) page data: (void *) data_ptr length: (uint64_t) len {
	page->data = data_ptr;
	page->length = len;
	page->rb_node.key = (void *)page;
}

-(void) configureRBtree {
	rb_red_blk_node *nild;
	nild = malloc(sizeof(*nild));
	tree = malloc(sizeof(*tree));
	memset(nild,0,sizeof(*nild));
	memset(tree,0,sizeof(*tree));
	RBTreeCreate(tree, nild, NULL, PagesComp, PagesDest, PagesInfoDest,
		     PagesPrint, PagesInfoPrint);
}

-(void) configureDataStruct: (struct data_struct *) ds length: (uint64_t) len {
	ds->data = malloc(len);
	memset(ds->data,0,len);
	ds->place = 0;
}

-(void) numberPages: (uint64_t) numpages path: (char *) pathname {
	uint64_t len;

	page_size = 4096;
	len = sizeof(struct page_struct) * (numpages + 1);
	[self configureDataStruct: &pages length: len];
	[self configureDataStruct: &data length: page_size * numpages];
	[self configureDataStruct: &cdata length: page_size * numpages];
	[self configureRBtree];
}

-(void) initialize {}

-(void) free {
	RBTreeDestroy(tree);

	free(pages.data);
	free(data.data);
	free(cdata.data);
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

@end

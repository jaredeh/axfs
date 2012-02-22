int PagesComp(const void* av, const void* bv)
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

void PagesDest(void* a) {;}

void PagesPrint(const void* a) {
	printf("%i",*(int*)a);
}

void InfoPrint(void* a) {;}

void InfoDest(void *a){;}

struct page_struct * PageAlloc(struct data_struct *pages_ptr)
{
	struct page_struct *retval;
	struct page_struct *page_list = (struct page_struct *) pages_ptr->data;
	retval = &page_list[pages_ptr->place];
	pages_ptr->place += 1;
	return retval;
}

void PagePopulate(struct page_struct *page, void *page_data, uint64_t page_length)
{
	page->data = page_data;
	page->length = page_length;
	page->rb_node.key = (void *)page;
}

static void configure_rbtree(rb_red_blk_tree **tree)
{
	rb_red_blk_node *nild;

	nild = malloc(sizeof(*nild));
	*tree = malloc(sizeof(**tree));
	memset(nild,0,sizeof(*nild));
	memset(*tree,0,sizeof(**tree));

	RBTreeCreate(*tree, nild, NULL, PagesComp, PagesDest, InfoDest, PagesPrint, InfoPrint);
}

static void configure_data_struct(struct data_struct *ds, uint64_t len)
{
	ds->data = malloc(len);
	memset(ds->data,0,len);
	ds->place = 0;
}

@implementation Pages

-(void) numberPages: (uint64_t) numpages path: (char *) pathname {
	uint64_t len;
	page_size = 4096;

	len = sizeof(struct page_struct) * (numpages + 1);
	configure_data_struct(&pages, len);
	configure_data_struct(&data, page_size * numpages);
	configure_data_struct(&cdata, page_size * numpages);
	configure_rbtree(&tree);
}

-(void) free {
	RBTreeDestroy(tree);

	free(pages.data);
	free(data.data);
	free(cdata.data);
}

-(void *) addPage: (void *) page_data length: (uint64_t) page_length {
	struct page_struct temp;
	struct page_struct *new_page;
	rb_red_blk_node *rb_node;

	memset(&temp,0,sizeof(temp));
	PagePopulate(&temp, page_data,page_length);
	rb_node = RBExactQuery(tree,(void *)&temp);
	if (rb_node)
		return rb_node->key;

	new_page = PageAlloc(&pages);
	PagePopulate(new_page, page_data, page_length);
	rb_node = &new_page->rb_node;
	RBTreeInsert(rb_node,tree,(void *)new_page,0);
	return rb_node->key;
}

@end

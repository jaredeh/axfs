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

-(uint64_t) hash: (struct page_struct *) temp {
	uint64_t hash = 0;
	uint8_t *str;
	int i;
	str = (uint8_t *) temp->data;

	for (i=0;i<temp->length;i++){
		hash += str[i];
	}

	return hash % hashlen;
}


-(void *) allocForAdd: (struct page_struct *) temp {
	struct page_struct *new_value;

	new_value = [self allocPageStruct];
	new_value->length = temp->length;
	new_value->data = [self allocPageData];
	memcpy(new_value->data, temp->data, new_value->length);
	new_value->cdata = [self allocPageCdata];
	[compressor cdata: new_value->cdata csize: &new_value->clength data: new_value->data size: new_value->length];

	memcpy(new_value->data, temp->data, temp->length);
	new_value->length = temp->length;
	return new_value;
}

-(void *) addPage: (void *) data_ptr length: (uint64_t) len {
	struct page_struct temp;
	struct page_struct *new_value;
	struct page_struct *list;
	uint64_t hash;

	memset(&temp,0,sizeof(temp));
	temp.data = data_ptr;
	temp.length = len;

	if (!deduped) {
		return [self allocForAdd: &temp];
	}

	hash = [self hash: &temp];

	if (hashtable[hash] == NULL) {
		new_value = [self allocForAdd: &temp];
		hashtable[hash] = new_value;
		return new_value;
	}

	list = hashtable[hash];
	while(true) {
		if (!PagesComp(list,&temp)) {
			return list;
		}
		if (list->next == NULL) {
			new_value = [self allocForAdd: &temp];
			list->next = new_value;
			return new_value;
		}
		list = list->next;
	}
}

-(id) init {
	uint64_t len;
	hashlen = AXFS_PAGES_HASHTABLE_SIZE;

	if (!(self = [super init]))
		return self;

	len = sizeof(struct page_struct) * (acfg.max_nodes + 1);
	[self configureDataStruct: &pages length: len];
	[self configureDataStruct: &data length: acfg.page_size * acfg.max_nodes];
	[self configureDataStruct: &cdata length: acfg.page_size * acfg.max_nodes];
	compressor = [[Compressor alloc] init];
	deduped = true;

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

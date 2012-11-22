#import "astrings.h"

static int StringsComp(const void* av, const void* bv)
{
	struct string_struct * a = (struct string_struct *)av;
	struct string_struct * b = (struct string_struct *)bv;
	void *adata = (void *)a->data;
	void *bdata = (void *)b->data;

	if( a->length > b->length )
		return 1;
	if( a->length < b->length )
		return -1;

	return memcmp(adata,bdata,a->length);
}

@implementation Strings

-(struct string_struct *) allocStringStruct {
	uint64_t d = sizeof(struct string_struct);
	return (struct string_struct *) [self allocData: &strings chunksize: d];
}

-(void *) allocStringData: (uint64_t) len {
	return (struct string_struct *) [self allocData: &data_obj chunksize: len];
}

-(void) populate: (struct string_struct *) str data: (void *) data_ptr length: (uint64_t) len {
	void *d;
	d = [self allocStringData: len];
	str->data = d;
	memcpy(str->data, data_ptr, len);
	str->length = len;
	str->rb_node.key = (void *)str;
}

-(void *) addString: (void *) data_ptr length: (uint64_t) len {
	struct string_struct temp;
	struct string_struct *new_string;
	rb_red_blk_node *rb_node;
	memset(&temp,0,sizeof(temp));
	temp.data = data_ptr;
	temp.length = len;
	rb_node = RBExactQuery(tree,(void *)&temp);
	if (rb_node)
		return rb_node->key;
	new_string = [self allocStringStruct];
	[self populate: new_string data: data_ptr length: len];
	rb_node = &new_string->rb_node;
	RBTreeInsert(rb_node,tree,(void *)new_string,0);

	return rb_node->key;
}

-(void *) data {
	data = data_obj.data;
	return data;
}

-(uint64_t) size {
	size = data_obj.used;
	return size;
}

-(uint64_t) length {
	return strings.place;
}

-(id) init {
	CompFunc = StringsComp;

	if (self = [super init]) {
		uint64_t len = sizeof(struct string_struct) * acfg.max_number_files;
		[self configureDataStruct: &strings length: len];
		[self configureDataStruct: &data_obj length: acfg.max_text_size];
	} 
	return self;
}

-(void) free {
	[super free];
	free(strings.data);
	free(data_obj.data);
}

@end

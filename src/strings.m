#import "strings.h"

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

static void StringsDest(void* a) {;}

static void StringsPrint(const void* a) {
	printf("%i",*(int*)a);
}

static void StringsInfoPrint(void* a) {;}

static void StringsInfoDest(void *a){;}

@implementation Strings

-(struct string_struct *) allocStringStruct {
	struct string_struct *retval;
	struct string_struct *strlist = (struct string_struct *) strings.data;
	retval = &strlist[strings.place];
	strings.place += 1;
	return retval;
}

-(void *) allocStringData: (uint64_t) len {
	void *retval;
	uint8_t *buffer = (uint8_t *) data.data;
	retval = &buffer[data.place];
	data.place += len;
	return retval;
}

-(void) populate: (struct string_struct *) str data: (void *) data_ptr length: (uint64_t) len {
	str->data = data_ptr;
	str->length = len;
	str->rb_node.key = (void *)str;
}

-(void) configureRBtree {
	rb_red_blk_node *nild;
	nild = malloc(sizeof(*nild));
	tree = malloc(sizeof(*tree));
	memset(nild,0,sizeof(*nild));
	memset(tree,0,sizeof(*tree));
	RBTreeCreate(tree, nild, NULL, StringsComp, StringsDest,
		     StringsInfoDest, StringsPrint, StringsInfoPrint);
}

-(void) configureDataStruct: (struct data_struct *) ds length: (uint64_t) len {
	ds->data = malloc(len);
	memset(ds->data,0,len);
	ds->place = 0;
}

-(void) numberInodes: (uint64_t) inodes length: (uint64_t) len path: (char *) pathname {
	uint64_t len1;

	len1 = sizeof(struct string_struct) * (inodes + 1);
	[self configureDataStruct: &strings length: len1];
	[self configureDataStruct: &data length: len];
	[self configureRBtree];
}

-(void) initialize {}

-(void) free {
	RBTreeDestroy(tree);
	free(strings.data);
	free(data.data);
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
	return data.data;
}

-(uint64_t) size {
	return data.place;
}

-(void *) cdata {
	Compressor * compressor;
	void *buffer;
	uint64_t len;

	if (cbuffer != NULL) {
		return cbuffer;
	}
	cbuffer = malloc([self size]);
	buffer = [self data];
	len = [self size];
	compressor = [[Compressor alloc] init];
	[compressor initialize];
	[compressor algorithm: "gzip"];
	[compressor cdata: cbuffer csize: &csize data: buffer size: len];
	[compressor free];
	[compressor release];
	if (csize == 0) {
		if (cbuffer == NULL)
			free(cbuffer);
		cbuffer = NULL;
	}

	return cbuffer;
}

-(uint64_t) csize {
	[self cdata];
	return csize;
}

-(uint64_t) length {
	return strings.place;
}

@end

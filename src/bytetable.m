int ByteTableComp(const void* av, const void* bv)
{
	struct bytetable_value *a = (struct bytetable_value *)av;
	struct bytetable_value *b = (struct bytetable_value *)bv;


	if( a->datum > b->datum )
		return 1;
	if( a->datum < b->datum )
		return -1;

	return 0;
}

void ByteTableDest(void* a) {;}

void ByteTablePrint(const void* av) {
	struct bytetable_value *a = (struct bytetable_value *)av;
	printf("0x%016llx", (long long unsigned int)a->datum);
}

void ByteTableInfoPrint(void* a) {;}

void ByteTableInfoDest(void* a){;}

static int ByteTable_check_depth(uint8_t depth, uint64_t datum) {
	uint64_t overflow = 0;

	overflow = datum & ~0xFFffFFffFFffFFULL;
	if ((overflow != 0) && (depth < 8))
		return 8;
	overflow = datum & ~0xFFffFFffFFffULL;
	if ((overflow != 0) && (depth < 7))
		return 7;
	overflow = datum & ~0xFFffFFffFFULL;
	if ((overflow != 0) && (depth < 6))
		return 6;
	overflow = datum & ~0xFFffFFffULL;
	if ((overflow != 0) && (depth < 5))
		return 5;
	overflow = datum & ~0xFFffFF;
	if ((overflow != 0) && (depth < 4))
		return 4;
	overflow = datum & ~0xFFff;
	if ((overflow != 0) && (depth < 3))
		return 3;
	overflow = datum & ~0xFF;
	if ((overflow != 0) && (depth < 2))
		return 2;
	if (depth < 1)
		return 1;
	return depth;
}

uint8_t output_byte1(uint64_t datum, uint8_t i)
{
	uint64_t mask;
	uint64_t byte;

	mask = 0xFF << (i*8);
	//printf("mask: 0x%016llx\n",(long long unsigned int)mask);
	byte = datum & mask;
	//printf("0byte:0x%016llx\n",(long long unsigned int)byte);
	byte = byte >> (i*8);
	//printf("1byte:0x%016llx\n",(long long unsigned int)byte);
	return (uint8_t) byte;
}

uint8_t * output_datum(uint8_t * buffer, uint8_t depth, uint64_t datum)
{
	int i;
	
	//printf("output datum 0x%016llx\n",(long long unsigned int)datum);
	for(i=0; i<depth; i++) {
		*buffer = output_byte1(datum, depth-1-i);
		buffer++;
	}
	return buffer;
}

struct bytetable_value * ByteTableValueAlloc(struct data_struct *bt)
{
	struct bytetable_value *retval;
	struct bytetable_value *list = (struct bytetable_value *) bt->data;

	retval = &list[bt->place];
	bt->place += 1;
	return retval;
}

@implementation ByteTable

-(void) configureRBtree {
	rb_red_blk_node *nild;
	nild = malloc(sizeof(*nild));
	tree = malloc(sizeof(*tree));
	memset(nild,0,sizeof(*nild));
	memset(tree,0,sizeof(*tree));
	RBTreeCreate(tree, nild, NULL, ByteTableComp, ByteTableDest,
		     ByteTableInfoDest, ByteTablePrint, ByteTableInfoPrint);
}

-(void) configureDataStruct: (struct data_struct *) ds length: (uint64_t) len {
	ds->data = malloc(len);
	memset(ds->data,0,len);
	ds->place = 0;
}

-(void) numberEntries: (uint64_t) entries dedup: (bool) dedup {
	uint64_t len;

	deduped = dedup;
	depth = 0;
	length = 0;
	len = sizeof(struct bytetable_value) * (entries + 1);
	[self configureDataStruct: &bytetable length: len];
	[self configureRBtree];
	dbuffer = NULL;
	cbuffer = NULL;
}

-(uint64_t) length {
	return length;
}

-(uint64_t) size {
	return length * depth;
}

-(void *) add: (uint64_t) datum {
	struct bytetable_value temp;
	struct bytetable_value *new_value;
	rb_red_blk_node *rb_node;

	if (deduped) {
		memset(&temp,0,sizeof(temp));
		temp.datum = datum;
		temp.rb_node.key = (void *)&temp;

		rb_node = RBExactQuery(tree,(void *)&temp);
		if (rb_node)
			return rb_node->key;
	}

	new_value = ByteTableValueAlloc(&bytetable);
	memset(new_value,0,sizeof(*new_value));
	new_value->datum = datum;
	new_value->rb_node.key = (void *)new_value;
	rb_node = &new_value->rb_node;
	if (deduped)
		RBTreeInsert(rb_node,tree,(void *)new_value,0);
	depth = ByteTable_check_depth(depth, datum);
	length += 1;
	return rb_node->key;
}

-(void *) data {
	uint64_t i=0;
	struct bytetable_value *value;
	uint8_t *buffer;

	if (dbuffer != NULL) {
		return dbuffer;
	}

	dbuffer = malloc([self size]);
	buffer = dbuffer;
	//printf("dbuffer=0x%08lx\n",(long unsigned int)dbuffer);
	for(i=0; i<length; i++) {
		//printf("buffer=0x%08lx\n",(long unsigned int)buffer);
		value = &((struct bytetable_value *)bytetable.data)[i];
		buffer = output_datum(buffer,depth,value->datum);
	}
	return dbuffer;
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
	[compressor initialize: "gzip"];
	[compressor cdata: cbuffer csize: &csize_cached data: buffer size: len];
	[compressor free];
	[compressor release];
	if (csize_cached == 0) {
		if (cbuffer == NULL)
			free(cbuffer);
		cbuffer = NULL;
	}

	return cbuffer;
}

-(uint64_t) csize {
	[self cdata];
	return csize_cached;
}

-(uint8_t) depth {
	return depth;
}

-(void) free {
	RBTreeDestroy(tree);

	free(bytetable.data);
	if (dbuffer != NULL)
		free(dbuffer);
	if (cbuffer != NULL)
		free(cbuffer);
}

@end

#import "bytetable.h"

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

@implementation ByteTable

-(void) checkDepth: (uint64_t) datum depth: (uint8_t *) i {
	uint64_t overflow = 0;

	overflow = datum & ~0xFFffFFffFFffFFULL;
	if ((overflow != 0) && (*i < 8)) {
		*i = 8;
		return;
	}
	overflow = datum & ~0xFFffFFffFFffULL;
	if ((overflow != 0) && (*i < 7)) {
		*i = 7;
		return;
	}
	overflow = datum & ~0xFFffFFffFFULL;
	if ((overflow != 0) && (*i < 6)) {
		*i = 6;
		return;
	}
	overflow = datum & ~0xFFffFFffULL;
	if ((overflow != 0) && (*i < 5)) {
		*i = 5;
		return;
	}
	overflow = datum & ~0xFFffFF;
	if ((overflow != 0) && (*i < 4)) {
		*i = 4;
		return;
	}
	overflow = datum & ~0xFFff;
	if ((overflow != 0) && (*i < 3)) {
		*i = 3;
		return;
	}
	overflow = datum & ~0xFF;
	if ((overflow != 0) && (*i < 2)) {
		*i = 2;
		return;
	}
	if (*i < 1) {
		*i = 1;
	}
}

-(struct bytetable_value *) allocByteTableValue: (struct data_struct *) bt {
	uint64_t d = sizeof(struct bytetable_value);
	return (struct bytetable_value *) [self allocData: bt chunksize: d];
}

-(void) numberEntries: (uint64_t) entries dedup: (bool) dedup {
	uint64_t len;

	deduped = dedup;
	len = sizeof(struct bytetable_value) * (entries + 1);
	[self configureDataStruct: &bytetable length: len];
}

-(uint64_t) length {
	return length;
}

-(uint64_t) size {
	size = length * depth;
	return size;
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

	new_value = [self allocByteTableValue: &bytetable];
	memset(new_value,0,sizeof(*new_value));
	new_value->datum = datum;
	new_value->rb_node.key = (void *)new_value;
	rb_node = &new_value->rb_node;
	if (deduped)
		RBTreeInsert(rb_node,tree,(void *)new_value,0);
	[self checkDepth: datum depth: &depth];
	length += 1;
	return rb_node->key;
}

-(void *) data {
	uint64_t i=0;
	struct bytetable_value *value;
	uint8_t *buffer;

	if (data != NULL) {
		return data;
	}

	[self size];
	data = malloc(size);
	buffer = data;
	//printf("dbuffer=0x%08lx\n",(long unsigned int)data);
	for(i=0; i<length; i++) {
		//printf("buffer=0x%08lx\n",(long unsigned int)buffer);
		value = &((struct bytetable_value *)bytetable.data)[i];
		buffer = [self outputDatum: value->datum depth: depth buffer: buffer];
	}
	return data;
}

-(uint8_t) depth {
	return depth;
}

-(id) init {
	CompFunc = ByteTableComp;
	if (!(self = [super init]))
		return self;

	depth = 0;
	length = 0;

	return self;
}

-(void) free {
	[super free];

	free(bytetable.data);
	if (data != NULL)
		free(data);
	if (cdata != NULL)
		free(cdata);
}

@end

#import "astrings.h"


@implementation Strings

-(struct string_struct *) allocStringStruct {
	uint64_t d = sizeof(struct string_struct);
	struct string_struct *s;
	s = (struct string_struct *) [self allocData: &strings chunksize: d];
	s->position = strings.place - 1;
	return s;
}

-(void *) allocStringData: (uint64_t) len {
	return (void *) [self allocData: &data_obj chunksize: len];
}

-(void) memcpyOutData: (struct string_struct *) str {
	void *dst;
	void *src;
	dst = (void *) [self allocData: &out_obj chunksize: str->length];
	src = str->data;
	printf("memcpyOutData:\"%s\"\n",(char *)src);
	memcpy(dst,src,str->length);
}

-(void *) allocForAdd: (struct string_struct *) temp {
	struct string_struct *new_value;

	new_value = [self allocStringStruct];
	if (temp->length == 0) {
		temp->length += 1;
	}
	new_value->data = [self allocStringData: temp->length];
	memcpy(new_value->data, temp->data, temp->length);
	new_value->length = temp->length;
	return new_value;
}

-(void *) addString: (void *) data_ptr length: (uint64_t) len {
	struct string_struct temp;

	memset(&temp,0,sizeof(temp));
	temp.data = data_ptr;
	temp.length = len;
	printf("addString: \"%s\"\n",(char *)data_ptr);

	return [self allocForAdd: &temp];
}

-(id) nameOffset {
	return nameOffset;
}

-(void) nameOrder: (void **) no {
	nameOrder = no;
}

-(void *) data {
	void **order = nameOrder;
	struct string_struct *str;
	printf("data 1\n");
	if (data)
		return data;
	printf("data 2\n");
	while(*order != NULL) {
	printf("data 3\n");
		str = (struct string_struct *)*order;
		order++;
		[nameOffset add: out_obj.used];
		[self memcpyOutData: str];
		data = out_obj.data;
	}
	printf("data 4\n");
	
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
	if (!(self = [super init]))
		return self;

	uint64_t len = sizeof(struct string_struct) * (acfg.max_number_files + 1);
	[self configureDataStruct: &strings length: len];
	[self configureDataStruct: &data_obj length: acfg.max_text_size + 1];
	[self configureDataStruct: &out_obj length: acfg.max_text_size + 1];
	nameOrder = 0;
	nameOffset = [[ByteTable alloc] init];
	[nameOffset numberEntries: acfg.max_number_files + 1 dedup: false];
	return self;
}

-(void) free {
	[super free];
	free(strings.data);
	free(data_obj.data);
	free(out_obj.data);
}

@end

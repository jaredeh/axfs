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
	struct string_struct *s;
	s = (struct string_struct *) [self allocData: &strings chunksize: d];
	s->position = strings.place - 1;
	return s;
}

-(void *) allocStringData: (uint64_t) len {
	printf("allocStringData = 0x%08x\n",data_obj.data);
	return (void *) [self allocData: &data_obj chunksize: len];
}

-(uint64_t) hash: (struct string_struct *) temp {
	uint64_t hash = 0;
	uint8_t *str;
	int i;
	str = (uint8_t *) temp->data;

	for (i=0;i<temp->length;i++){
		hash += str[i];
	}

	return hash % hashlen;
}

-(void *) allocForAdd: (struct string_struct *) temp {
	struct string_struct *new_value;

	new_value = [self allocStringStruct];
	if (temp->length) {
		temp->length += 1;
	}
	new_value->data = [self allocStringData: temp->length];
	memcpy(new_value->data, temp->data, temp->length);
	new_value->length = temp->length;
	printf("allocForAdd = '%s' 0x%08x '%s'\n",new_value->data,new_value->data,temp->data);
	return new_value;
}

-(void *) addString: (void *) data_ptr length: (uint64_t) len {
	struct string_struct temp;
	struct string_struct *new_value;
	struct string_struct *list;
	uint64_t hash;

	printf("addString: '%s'\n",data_ptr);
	printf("addString data='%s' 0x%08x  0x%08x\n",data,data,data_obj.data);

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
		if (!StringsComp(list,&temp)) {
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

-(void *) data {
	data = data_obj.data;
	printf("astring data='%s' 0x%08x  0x%08x\n",data,data,data_obj.data);
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
	printf("astring init\n");
	hashlen = AXFS_STRINGS_HASHTABLE_SIZE;
	if (!(self = [super init]))
		return self;

	uint64_t len = sizeof(struct string_struct) * (acfg.max_number_files + 1);
	[self configureDataStruct: &strings length: len];
	[self configureDataStruct: &data_obj length: acfg.max_text_size];
	deduped = true;
 
	return self;
}

-(void) free {
	[super free];
	free(strings.data);
	free(data_obj.data);
}

@end

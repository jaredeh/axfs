#import "btree_object.h"

@implementation BtreeObject

-(void *) allocData: (struct data_struct *) ds chunksize: (uint64_t) chunksize {
	void *retval;
	uint8_t *buffer = (uint8_t *) ds->data;
	retval = &buffer[ds->used];
	ds->place += 1;
	ds->used += chunksize;
	//printf("allocData place=%i used=%i\n",ds->place, ds->used);
	if (ds->used > ds->total) {
		[NSException raise: @"Overalloced" format: @"ds.used=%d while ds.total=%d",ds->used,ds->total];
	}
	return retval;
}

-(void) configureDataStruct: (struct data_struct *) ds length: (uint64_t) len {
	if (!len) {
		[NSException raise: @"Can't configure data struct" format: @"len must be > 0"];
	}
	if (!ds) {
		[NSException raise: @"Can't configure data struct" format: @"ds can't be NULL"];
	}
	ds->data = malloc(len);
	memset(ds->data,0,len);
	ds->place = 0;
	ds->used = 0;
	ds->total = len;
}

-(uint8_t) depth {
	return 0;
}

-(Region *) region {
	return region;
}

-(void) fsalign: (uint64_t) align {
	fsalign = align;
}

-(void) fsoffset: (uint64_t) offset {
	printf("1offset=%d fsoffset=%d fsalign=%d\n",(int)offset,(int)fsoffset,(int)fsalign);
	fsoffset = [self alignNumber: offset bytes: fsalign];
	printf("2offset=%d fsoffset=%d fsalign=%d\n",(int)offset,(int)fsoffset,(int)fsalign);
}

-(uint64_t) fsoffset {
	return fsoffset;
}

-(id) init {
	uint64_t len;

	if (!(self = [super init]))
		return self;

	region = [[Region alloc] init];
	[region add: self];

	len = sizeof(*hashtable) * hashlen;
	if (len > 0) {
		[self configureDataStruct: &hashablestruct length: len];
		hashtable = hashablestruct.data;
	}

	deduped = false;

	return self;
}

-(void) free {
	if (hashtable != NULL)
		free(hashtable);
}

@end

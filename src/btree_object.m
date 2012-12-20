#import "btree_object.h"

static void DestFunc(void* a) {;}

static void PrintFunc(const void* a) {
	printf("%i",*(int*)a);
}

static void PrintInfo(void* a) {;}

static void InfoDestFunc(void *a){;}

@implementation BtreeObject

-(void *) allocData: (struct data_struct *) ds chunksize: (uint64_t) chunksize {
	void *retval;
	uint8_t *buffer = (uint8_t *) ds->data;
	retval = &buffer[ds->used];
	ds->place += 1;
	ds->used += chunksize;
	if (ds->used > ds->total) {
		[NSException raise: @"Overalloced" format: @"ds.used=%d while ds.total=%d",ds->used,ds->total];
	}
	return retval;
}

-(void) configureRBtree {
	rb_red_blk_node *nild;
	nild = malloc(sizeof(*nild));
	tree = malloc(sizeof(*tree));
	memset(nild,0,sizeof(*nild));
	memset(tree,0,sizeof(*tree));
	RBTreeCreate(tree, nild, NULL, CompFunc, DestFunc, InfoDestFunc,
		     PrintFunc, PrintInfo);
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

-(Region *) region {
	return region;
}

-(void) fsalign: (uint64_t) align {
	fsalign = align;
}

-(void) fsoffset: (uint64_t) offset {
	fsoffset = [self alignNumber: offset bytes: fsalign];
}

-(uint64_t) fsoffset {
	return fsoffset;
}

-(id) init {
	if (!(self = [super init]))
		return self;

	[self configureRBtree];
	region = [[Region alloc] init];
	[region add: self];

	return self;
}

-(void) free {
	RBTreeDestroy(tree);
}

@end

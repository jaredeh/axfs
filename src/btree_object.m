#import "btree_object.h"

static void DestFunc(void* a) {;}

//static void PrintFunc(const void* a) {
//	printf("%i",a);
//}

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

-(void) inorderTree: (InorderProcessFuncType) p {
	printf("START inorderTree\n");
	RBTreePrint(tree);
	[self inorderTreeProcess: tree->root->left processor: p];
	printf("END inorderTree\n");
}

-(void) inorderTreeProcess: (rb_red_blk_node*) x processor: (InorderProcessFuncType) p {
	printf("inorderTreeProcess: x=0x%08llx t=0x%08llx n=0x%08llx r=0x%08llx\n",(unsigned long long)x,(unsigned long long)tree,(unsigned long long)nild,(unsigned long long)root);

	if (x == nild)
		return;
	if (x == NULL)
		return;

	printf("-->");
	p(x->key);
	printf("<--\n");

	//printf("<--left\n");
	[self inorderTreeProcess: x->left processor: p];
	/*
	printf("info=");
	tree->PrintInfo(x->info);
	printf("  key="); 
	tree->PrintKey(x->key);
	printf("  l->key=");
	if( x->left == nild) printf("NULL"); else tree->PrintKey(x->left->key);
	printf("  r->key=");
	if( x->right == nild) printf("NULL"); else tree->PrintKey(x->right->key);
	printf("  p->key=");
	if( x->parent == root) printf("NULL"); else tree->PrintKey(x->parent->key);
	printf("  red=%i\n",x->red);
	*/
	//printf("right-->\n");
	[self inorderTreeProcess: x->right processor: p];
	//printf("}\n");
}

-(void) configureRBtree {
	nild = malloc(sizeof(*nild));
	tree = malloc(sizeof(*tree));
	root = malloc(sizeof(*root));
	memset(nild,0,sizeof(*nild));
	memset(tree,0,sizeof(*tree));
	memset(root,0,sizeof(*root));
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
	//printf("1offset=%d fsoffset=%d fsalign=%d\n",(int)offset,(int)fsoffset,(int)fsalign);
	fsoffset = [self alignNumber: offset bytes: fsalign];
	//printf("2offset=%d fsoffset=%d fsalign=%d\n",(int)offset,(int)fsoffset,(int)fsalign);
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

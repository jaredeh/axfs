#import "modes.h"

static int ModesCompHelper(uint64_t a, uint64_t b) {
	if (a > b)
		return 1;
	if (a < b)
		return -1;
	return 0;
}

static int ModesComp(const void* av, const void* bv)
{
	struct mode_struct * a = (struct mode_struct *)av;
	struct mode_struct * b = (struct mode_struct *)bv;
	int retval;

	retval = ModesCompHelper((uint64_t) a->mode, (uint64_t) b->mode);
	if (retval != 0)
		return retval;

	retval = ModesCompHelper((uint64_t) a->gid, (uint64_t) b->gid);
	if (retval != 0)
		return retval;

	return ModesCompHelper((uint64_t) a->uid, (uint64_t) b->uid);
}

static void ModesDest(void* a) {;}

static void ModesPrint(const void* a) {
	printf("%i",*(int*)a);
}

static void ModesInfoPrint(void* a) {;}

static void ModesInfoDest(void *a){;}

@implementation Modes

-(struct mode_struct *) allocModeStruct {
	struct mode_struct *retval;
	struct mode_struct *mode_list = (struct mode_struct *) modes.data;
	retval = &mode_list[modes.place];
	modes.place += 1;
	modes.used += sizeof(*retval);
	if (modes.used > modes.total) {
		[NSException raise: @"Overalloced mode_structs" format: @"modes.used=%d while modes.total=%d",modes.used,modes.total];
	}
	return retval;
}

-(void) configureRBtree {
	rb_red_blk_node *nild;
	nild = malloc(sizeof(*nild));
	tree = malloc(sizeof(*tree));
	memset(nild,0,sizeof(*nild));
	memset(tree,0,sizeof(*tree));
	RBTreeCreate(tree, nild, NULL, ModesComp, ModesDest, ModesInfoDest,
		     ModesPrint, ModesInfoPrint);
}

-(void) configureDataStruct: (struct data_struct *) ds length: (uint64_t) len {
	ds->data = malloc(len);
	memset(ds->data,0,len);
	ds->place = 0;
	ds->used = 0;
	ds->total = len;
}

-(void *) addMode: (NSDictionary *) attribs {
	struct mode_struct temp;
	struct mode_struct *new_mode;
	rb_red_blk_node *rb_node;
	uint32_t gid;
	uint32_t uid;
	uint16_t mode;

	memset(&temp,0,sizeof(temp));
	gid = (uint32_t)[[attribs objectForKey:NSFileGroupOwnerAccountID] unsignedLongValue];
	uid = (uint32_t)[[attribs objectForKey:NSFileOwnerAccountID] unsignedLongValue];
	mode = (uint16_t)[[attribs objectForKey:NSFilePosixPermissions] shortValue];
	temp.gid = gid;
	temp.uid = uid;
	temp.mode = mode;
	rb_node = RBExactQuery(tree,(void *)&temp);
	if (rb_node)
		return rb_node->key;
	new_mode = [self allocModeStruct];
	new_mode->gid = gid;
	new_mode->uid = uid;
	new_mode->mode = mode;
	new_mode->rb_node.key = (void *) new_mode;
	rb_node = &new_mode->rb_node;
	RBTreeInsert(rb_node,tree,(void *)new_mode,0);

	return rb_node->key;
}

-(id) init {
	if (self = [super init]) {
		uint64_t len;
		len = sizeof(struct mode_struct) * (acfg.max_number_files + 1);
		[self configureDataStruct: &modes length: len];
		[self configureRBtree];
	} 
	return self;
}

-(uint64_t) length {
	return modes.place;
}

-(void) free {
	RBTreeDestroy(tree);
	free(modes.data);
}

@end

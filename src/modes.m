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

@implementation Modes

-(struct mode_struct *) allocModeStruct {
	uint64_t d = sizeof(struct mode_struct);
	return (struct mode_struct *) [self allocData: &modes chunksize: d];
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

-(uint64_t) length {
	return modes.place;
}

-(id) modesTable {
	return modesTable;
}

-(id) uids {
	return uids;
}

-(id) gids {
	return gids;
}

-(id) init {
	CompFunc = ModesComp;
	if (self = [super init]) {
		uint64_t len;
		len = sizeof(struct mode_struct) * (acfg.max_number_files + 1);
		[self configureDataStruct: &modes length: len];
	}

	modesTable = [[ByteTable alloc] init];
	uids = [[ByteTable alloc] init];
	gids = [[ByteTable alloc] init];

	return self;
}

-(void) free {
	[super free];
	free(modes.data);
}

@end

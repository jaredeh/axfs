#import "modes.h"

/*
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
*/

@implementation Modes

-(struct mode_struct *) allocModeStruct {
	uint64_t d = sizeof(struct mode_struct);
	struct mode_struct *m;
	m = [self allocData: &modes chunksize: d];
	m->position = modes.place - 1;
	return m;
}

-(uint64_t) hash: (struct mode_struct *) temp {
	uint64_t hash;

	hash = temp->gid;
	hash = hash << 32;
	hash += temp->uid;
	hash += temp->mode;

	return hash % hashlen;
}

-(void *) allocForAdd: (struct mode_struct *) temp {
	struct mode_struct *new_mode;
	
	new_mode = [self allocModeStruct];
	new_mode->gid = temp->gid;
	new_mode->uid = temp->uid;
	new_mode->mode = temp->mode;
	return new_mode;
}

-(void *) addMode: (struct stat *) sb {
	struct mode_struct temp;
	struct mode_struct *new_value;
	struct mode_struct *list;
	uint64_t hash;
	uint32_t gid;
	uint32_t uid;
	uint32_t mode;

	memset(&temp,0,sizeof(temp));
	gid = (uint32_t)sb->st_gid;
	uid = (uint32_t)sb->st_uid;
	mode = (uint32_t)sb->st_mode;
	temp.gid = gid;
	temp.uid = uid;
	temp.mode = mode;
	printf("  addMode 0x%08x 0x%08x 0x%08x\n",mode,gid,uid);
	printf("  addMode 0x%08x 0x%08x 0x%08x\n",sb->st_mode,sb->st_gid,sb->st_uid);
	printf("  addMode isdir %i\n",S_ISDIR(mode));
	if (!deduped) {
		printf("b0\n");
		return [self allocForAdd: &temp];
	}

	hash = [self hash: &temp];

	if (hashtable[hash] == NULL) {
		new_value = [self allocForAdd: &temp];
		hashtable[hash] = new_value;
		printf("b1\n");
		return new_value;
	}

	list = hashtable[hash];
	while(true) {
		if ((list->gid == gid)&&(list->uid == uid)&&(list->mode == mode)){
			printf("b2\n");
			return list;
		}
		if (list->next == NULL) {
			new_value = [self allocForAdd: &temp];
			list->next = new_value;
			printf("b3\n");
			return new_value;
		}
		list = list->next;
	}
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

-(void) split: (struct mode_struct *) mode {
	ByteTable *bt;

	printf("split\n");
	if (mode == NULL)
		return;
	printf("mode=%i uid=%i gid =%i\n",(int)mode->mode,(int)mode->uid,(int)mode->gid);
	bt = [aobj.modes modesTable];
	[bt add: mode->mode];
	bt = [aobj.modes uids];
	[bt add: mode->uid];
	bt = [aobj.modes gids];
	[bt add: mode->gid];
}

-(void *) data {
	struct mode_struct *m;
	uint64_t i=0;
	printf("modes data\n");
	m = modes.data;
	while(i<modes.place) {
		[self split: &m[i]];
		i++;
	}
	return NULL;
}

-(id) init {
	uint64_t len;
	hashlen = AXFS_MODES_HASHTABLE_SIZE;

	if (!(self = [super init]))
		return self;

	deduped = true;
	len = sizeof(struct mode_struct) * (acfg.max_number_files + 1);
	[self configureDataStruct: &modes length: len];

	modesTable = [[ByteTable alloc] init];
	uids = [[ByteTable alloc] init];
	gids = [[ByteTable alloc] init];
	[modesTable numberEntries: acfg.max_number_files dedup: false];
	[uids numberEntries: acfg.max_number_files dedup: false];
	[gids numberEntries: acfg.max_number_files dedup: false];

	return self;
}

-(void) free {
	[super free];
	free(modes.data);
}

@end

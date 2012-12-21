#import "inodes.h"
#include <sys/stat.h>


//use path
static int InodesComp(const void* av, const void* bv)
{
	struct inode_struct * a = (struct inode_struct *)av;
	struct inode_struct * b = (struct inode_struct *)bv;
	void *adata = (void *)a->data;
	void *bdata = (void *)b->data;

	if( a->length > b->length )
		return 1;
	if( a->length < b->length )
		return -1;

	return memcmp(adata,bdata,a->length);
}

static int InodeNameComp(const void *x, const void *y) {
	int min;
	int retval;
	struct inode_struct *a = (struct inode_struct *) x;
	struct inode_struct *b = (struct inode_struct *) y;

	min = b->name->length;
	if (a->name->length < b->name->length)
		min = a->name->length;

	retval = strncmp(a->name->data,b->name->data, min);

	if (a->name->length == b->name->length)
		return retval;

	if (retval != 0)
		return retval;

	if (a->name->length > b->name->length)
		return 1;

	return -1;
}

@implementation Inodes

-(struct inode_struct *) allocInodeStruct {
	uint64_t d = sizeof(struct inode_struct);
	return (struct inode_struct *) [self allocData: &inodes chunksize: d];
}

-(struct inode_struct **) allocInodeList: (uint64_t) len {
	uint64_t d = sizeof(struct inode_struct *) * len;
	return (struct inode_struct **) [self allocData: &inode_list chunksize: d];
}

-(struct node_struct **) allocNodeList: (uint64_t) len {
	uint64_t d = sizeof(struct node_struct *) * len;
	return (struct node_struct **) [self allocData: &node_list chunksize: d];
}

-(void) placeInDirectory: (struct inode_struct *) inode {
	struct inode_struct *parent;
	NSString *directory;
	struct inode_struct **list;
	uint64_t pos;

	directory = [inode->path stringByDeletingLastPathComponent];

	parent = [paths findParentInodeByPath: directory];
	if (!parent)
		return;

	list = parent->list.inodes;
	pos = parent->list.position;
	parent->list.position++;
	list[pos] = inode;
	//only want to qsort when we call data
	qsort(list,parent->list.position,sizeof(inode),InodeNameComp);
}

-(void *) addInode_symlink: (struct inode_struct *) inode {
	const char *str;
	int err;

	str = [inode->path UTF8String];

	if (symlink.total < inode->size) {
		free(symlink.data);
		symlink.data = malloc(inode->size);
		symlink.total = inode->size;
	}

	err = readlink(str, symlink.data, inode->size);
	if (err < 0)
		[NSException raise: @"readlink" format: @"readlink() returned error# %i",err];
	//FIXME: actually copy data here

	return inode;
}

-(void *) addInode_devnode: (struct inode_struct *) inode {
	struct stat sb;
	const char *str;

	str = [inode->path UTF8String];
	stat(str, &sb);
	inode->size = sb.st_rdev;
	return inode;
}

-(void *) addInode_regularfile: (struct inode_struct *) inode {
	NSFileHandle *file;
	NSData *databuffer;
	uint64_t data_read = 0;
	NSUInteger d;
	struct entry_list *list;

	list = &inode->list;

	file = [NSFileHandle fileHandleForReadingAtPath: inode->path];

	if (file == nil) {
		NSFileManager *fm = [NSFileManager defaultManager];
		[NSException raise: @"Bad file" format: @"Failed to open file at path=%@ from %@",inode->path, [fm currentDirectoryPath]];
	}

	list->length = inode->size / acfg.page_size + 1;
	list->node = [self allocNodeList: list->length];

	while (data_read < inode->size) {
		databuffer = [file readDataOfLength: acfg.page_size];
		d = [databuffer length];
		data_read += d;
		//printf("d = %llu data_read = %llu size = %llu \n", d, data_read, size);
	}

	[file closeFile];

	//FIXME: actually copy data
	return inode;
}

-(void *) addInode_directory: (struct inode_struct *) inode {
	NSDirectoryEnumerator *em;
	struct entry_list *list;
	NSString* file;
	uint64_t count = 0;

	//NSArray *dir  = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: inode->path error:nil];
	em = [[NSFileManager defaultManager] enumeratorAtPath: inode->path];
	[em skipDescendents];
	while ((file = [em nextObject])) {
		count++;
	}



	list = &inode->list;
	list->length = [dir count];
	list->inodes = [self allocInodeList: list->length];
	[paths addPath: inode];
	return inode;
}

-(void *) addInode: (NSString *) path {
	NSString *filetype;
	NSString *name;
	struct inode_struct *inode;
	NSDictionary *attribs;

	attribs = [[NSFileManager alloc] attributesOfItemAtPath: path error: nil];
	name = [path lastPathComponent];
	inode = [self allocInodeStruct];
	inode->size = (uint64_t)[[attribs objectForKey:NSFileSize] unsignedLongLongValue];
	inode->path = path;
	inode->name = [strings addString: (void *)[name UTF8String] length: [name length]];
	inode->mode = [modes addMode: attribs];
	//redundant files
	filetype = [attribs objectForKey:NSFileType];
	if (filetype == NSFileTypeSymbolicLink) {
		[self addInode_symlink: inode];
	} else if (filetype == NSFileTypeCharacterSpecial) {
		[self addInode_devnode: inode];
	} else if (filetype == NSFileTypeBlockSpecial) {
		[self addInode_devnode: inode];
	} else if (filetype == NSFileTypeDirectory) {
		[self addInode_directory: inode];
	} else if (filetype == NSFileTypeRegular) {
		[self addInode_regularfile: inode];
	}
	if (filetype != NSFileTypeDirectory) {
		[self placeInDirectory: inode];
	}

	inode->path = NULL;
	return inode;
}

-(id) fileSizeIndex {
	return fileSizeIndex;
}

-(id) nameOffset {
	return nameOffset;
}

-(id) numEntriescblockOffset {
	return numEntriescblockOffset;
}

-(id) modeIndex {
	return modeIndex;
}

-(id) arrayIndex {
	return arrayIndex;
}

-(id) init {
	uint64_t len;
	CompFunc = InodesComp;

	if (!(self = [super init]))
		return self;

	len = sizeof(struct inode_struct) * (acfg.max_nodes + 1);
	[self configureDataStruct: &inodes length: len];
	[self configureDataStruct: &data length: acfg.page_size * acfg.max_nodes];
	[self configureDataStruct: &cdata length: acfg.page_size * acfg.max_nodes];
	[self configureDataStruct: &symlink length: acfg.page_size];
	[self configureDataStruct: &inode_list length: acfg.max_nodes * sizeof(struct inode_struct *)];
	[self configureDataStruct: &node_list length: acfg.max_nodes * sizeof(struct node_struct *)];
	paths = [[Paths alloc] init];
	strings = [[Strings alloc] init];
	modes = [[Modes alloc] init];

	return self;
}

-(void) free {
	[super free];

	free(inodes.data);
	free(data.data);
	free(cdata.data);
	free(symlink.data);
	free(inode_list.data);
	free(node_list.data);
}

@end

static int PathsComp(const void* av, const void* bv)
{
	struct paths_struct *a = (struct paths_struct *)av;
	struct paths_struct *b = (struct paths_struct *)bv;
	NSString *apath = (NSString *)a->inode->path;
	NSString *bpath = (NSString *)b->inode->path;
	int retval;
	NSComparisonResult res = [apath compare: bpath];
 
	switch (res) {
		case NSOrderedAscending:
			retval = 1;
			break;
		case NSOrderedSame:
			retval = 0;
			break;
		case NSOrderedDescending:
			retval = -1;
			break;
		default:
			retval = 1;
			break;
	}
	return retval;
}

@implementation Paths

-(struct paths_struct *) allocPathStruct {
	uint64_t d = sizeof(struct paths_struct);
	return (struct paths_struct *) [self allocData: &data chunksize: d];
}

-(void *) addPath: (struct inode_struct *) inode {
	struct paths_struct temp;
	struct paths_struct *new_path;
	rb_red_blk_node *rb_node;

	memset(&temp,0,sizeof(temp));
	temp.inode = inode;
	rb_node = RBExactQuery(tree,(void *)&temp);
	if (rb_node)
		return rb_node->key;
	new_path = [self allocPathStruct];
	new_path->inode = temp.inode;
	rb_node = &new_path->rb_node;
	RBTreeInsert(rb_node,tree,(void *)new_path,0);

	return rb_node->key;
}

-(void *) findParentInodeByPath: (NSString *) path {
	struct paths_struct temp;
	struct paths_struct *parent_paths;
	struct inode_struct inode;
	struct inode_struct *parent;
	rb_red_blk_node *rb_node;

	memset(&temp,0,sizeof(temp));
	memset(&inode,0,sizeof(inode));
	inode.path = path;
	temp.inode = &inode;
	rb_node = RBExactQuery(tree,(void *)&temp);
	if (rb_node) {
		parent_paths = (struct paths_struct *)rb_node->key;
		parent = parent_paths->inode;
		return parent;
	}

	return NULL;
}

-(id) init {
	CompFunc = PathsComp;
	if (self = [super init]) {
		uint64_t len;
		len = sizeof(struct paths_struct) * (acfg.max_number_files + 1);
		[self configureDataStruct: &data length: len];
	} 
	return self;
}

-(void) free {
	[super free];
	free(data.data);
}

@end


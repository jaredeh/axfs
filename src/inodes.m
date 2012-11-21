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

static void InodesDest(void* a) {;}

static void InodesPrint(const void* a) {
	printf("%i",*(int*)a);
}

static void InodesInfoPrint(void* a) {;}

static void InodesInfoDest(void *a){;}

@implementation Inodes

-(struct inode_struct *) allocInodeStruct {
	struct inode_struct *retval;
	struct inode_struct *inode_list = (struct inode_struct *) inodes.data;
	retval = &inode_list[inodes.place];
	inodes.place += 1;
	return retval;
}

-(void) configureRBtree {
	rb_red_blk_node *nild;
	nild = malloc(sizeof(*nild));
	tree = malloc(sizeof(*tree));
	memset(nild,0,sizeof(*nild));
	memset(tree,0,sizeof(*tree));
	RBTreeCreate(tree, nild, NULL, InodesComp, InodesDest, InodesInfoDest,
		     InodesPrint, InodesInfoPrint);
}

-(void) configureDataStruct: (struct data_struct *) ds length: (uint64_t) len {
	ds->data = malloc(len);
	memset(ds->data,0,len);
	ds->place = 0;
}

-(void) placeInDirectory: (struct inode_struct *) inode {
	struct inode_struct *parent;
	NSString *directory;
	directory = [inode->path stringByDeletingLastPathComponent];

	parent = [paths findParentInodeByPath: directory];
	if (!parent)
		return;

	//parent  //put inode in list
}

-(void *) addInode_symlink: (struct inode_struct *) inode {
	NSFileManager *fm;
	NSString *link;

	fm = [NSFileManager defaultManager];
	link = [fm destinationOfSymbolicLinkAtPath: inode->path error: NULL];

	inode->size = (uint64_t)[link length];
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

	file = [NSFileHandle fileHandleForReadingAtPath: inode->path];

	if (file == nil) {
		NSFileManager *fm = [NSFileManager defaultManager];
		NSLog(@"Failed to open file at path=%@ from %@",inode->path, [fm currentDirectoryPath]);
		return NULL;
	}

	while (data_read < inode->size) {
		databuffer = [file readDataOfLength: acfg.page_size];
		d = [databuffer length];
		data_read += d;
		//printf("d = %llu data_read = %llu size = %llu \n", d, data_read, size);
	}

	[file closeFile];

	return inode;
}

-(void *) addInode_directory: (struct inode_struct *) inode {
	inode->is_dir = 1;
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
	printf("a00\n");
	inode->name = [strings addString: (void *)[name UTF8String] length: [name length]];
	printf("a01\n");
	inode->mode = [modes addMode: attribs];
	printf("a02\n");
	//deal with mode
	//redundant files
   //wrong... have inode struct be home for all this, pass the inode struct in then we can as
	filetype = [attribs objectForKey:NSFileType];
	printf("a03\n");
	if (filetype == NSFileTypeSymbolicLink) {
		printf("a04\n");
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
		struct inode_struct *parent;
		//NSString *directory = inode->path;
		parent = [paths findParentInodeByPath: inode->path];
	}

	inode->path = NULL;
	return inode;
}

-(id) init {
	if (self = [super init]) {
		uint64_t len;
		len = sizeof(struct inode_struct) * (acfg.max_nodes + 1);
		[self configureDataStruct: &inodes length: len];
		[self configureDataStruct: &data length: acfg.page_size * acfg.max_nodes];
		[self configureDataStruct: &cdata length: acfg.page_size * acfg.max_nodes];
		[self configureRBtree];
		paths = [[Paths alloc] init];
		strings = [[Strings alloc] init];
		modes = [[Modes alloc] init];
	} 
	return self;
}

-(void) free {
	RBTreeDestroy(tree);

	free(inodes.data);
	free(data.data);
	free(cdata.data);
}

@end

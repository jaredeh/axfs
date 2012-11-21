#import "paths.h"
#include <sys/stat.h>


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

static void PathsDest(void* a) {;}

static void PathsPrint(const void* a) {
	printf("%i",*(int*)a);
}

static void PathsInfoPrint(void* a) {;}

static void PathsInfoDest(void *a){;}

@implementation Paths

-(struct paths_struct *) allocPathStruct {
	struct paths_struct *retval;
	struct paths_struct *list = (struct paths_struct *) data.data;
	retval = &list[data.place];
	data.place += 1;
	return retval;
}

-(void) configureRBtree {
	rb_red_blk_node *nild;
	nild = malloc(sizeof(*nild));
	tree = malloc(sizeof(*tree));
	memset(nild,0,sizeof(*nild));
	memset(tree,0,sizeof(*tree));
	RBTreeCreate(tree, nild, NULL, PathsComp, PathsDest, PathsInfoDest,
		     PathsPrint, PathsInfoPrint);
}

-(void) configureDataStruct: (struct data_struct *) ds length: (uint64_t) len {
	ds->data = malloc(len);
	memset(ds->data,0,len);
	ds->place = 0;
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
	if (rb_node)
		parent_paths = (struct paths_struct *)rb_node->key;
		parent = parent_paths->inode;
		return parent;
	return NULL;
}

-(id) init {
	if (self = [super init]) {
		uint64_t len;
		len = sizeof(struct paths_struct) * (acfg.max_number_files + 1);
		[self configureDataStruct: &data length: len];
		[self configureRBtree];
	} 
	return self;
}

-(void) free {
	RBTreeDestroy(tree);

	free(data.data);
}

@end

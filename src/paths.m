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

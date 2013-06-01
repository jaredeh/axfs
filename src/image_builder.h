#import <Foundation/Foundation.h>
#import "axfs_helper.h"
#import "axfs_objects.h"
#import "dir_walker.h"
#import "super.h"
#import "region_descriptors.h"
#import "astrings.h"
#import "nodes.h"
#import "inodes.h"
#import "tomcrypt.h"

//20 unique segments of data, assume each could have padding
#define AXFS_MAX_DATASSEGMENTS 40

extern struct axfs_objects aobj;

struct data_segment {
	void *data;
	char *name;
	uint64_t size;
	uint64_t start;
	uint64_t end;
	uint64_t written;
};

@interface ImageBuilder: NSObject {
	DirWalker *dw;
	Super *sb;
	RegionDescriptors *rd;
	struct data_segment data_segments[AXFS_MAX_DATASSEGMENTS];
	int current_segment;
}
-(void) setupObjs;
-(void) setupRegions;
-(void) build;
-(void) sizeup;
-(void) walk;
-(void) free;
@end


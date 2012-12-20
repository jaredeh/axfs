#import "xip_nodes.h"
#import "ba_nodes.h"
#import "comp_nodes.h"
#import "bytetable.h"
#include "linux/axfs_ducttape.h"
#include "linux/axfs_fs.h"

@interface Nodes: NSObject {
	XipNodes *xip;
	BaNodes *byte_aligned;
	CompNodes *compressed;
	ByteTable *node_type;
	ByteTable *node_index;
}

-(uint64_t) addPage: (void *) page;
-(uint64_t) length;
-(id) xip;
-(id) byte_aligned;
-(id) compressed;
-(id) nodeType;
-(id) nodeIndex;
-(uint64_t) size;
-(uint64_t) csize;
-(void) free;

@end


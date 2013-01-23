#import "xip_nodes.h"
#import "ba_nodes.h"
#import "comp_nodes.h"
#import "bytetable.h"
#include "linux/axfs_ducttape.h"
#include "linux/axfs_fs.h"

struct axfs_nodes {
	uint64_t index;
	uint8_t type;
	struct axfs_nodes *next;
};

@interface Nodes: NSObject {
	XipNodes *xip;
	BaNodes *byte_aligned;
	CompNodes *compressed;
	ByteTable *node_type;
	ByteTable *node_index;
	struct axfs_nodes *nodes;
	struct data_struct nodes_data;
	uint64_t current;
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
-(void *) data;
-(void) free;

@end


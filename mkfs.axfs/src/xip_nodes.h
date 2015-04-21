#import "nodes_object.h"
#import "bytetable.h"

extern struct axfs_config acfg;

@interface XipNodes: NodesObject {
	NSMutableDictionary *profile;
}
-(bool) pageIsXip: (NSString *) path offset: (uint64_t) offset;
-(void *) data;
-(void) free;

@end


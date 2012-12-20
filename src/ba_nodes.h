#import "nodes_object.h"
#import "bytetable.h"

@interface BaNodes: NodesObject {
	ByteTable *banodeOffset;
}
-(void *) data;
-(id) banodeOffset;
-(void) free;

@end


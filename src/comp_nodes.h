#import "nodes_object.h"
#import "c_blocks.h"
#import "bytetable.h"

@interface CompNodes: NodesObject {
	CBlocks *cb;
}
-(void *) data;
-(id) cnodeOffset;
-(id) cnodeIndex;
-(id) cblockOffset;
-(void) free;

@end


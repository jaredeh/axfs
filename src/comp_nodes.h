#import "nodes_object.h"
#import "c_blocks.h"
#import "bytetable.h"

@interface CompNodes: NodesObject {
	CBlocks *cb;
	ByteTable *cnodeOffset;
	ByteTable *cnodeIndex;
	ByteTable *cblockOffset;
}
-(void *) data;
-(id) cnodeOffset;
-(id) cnodeIndex;
-(id) cblockOffset;
-(void) free;

@end


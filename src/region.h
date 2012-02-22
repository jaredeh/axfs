#import <Foundation/NSObject.h>
#import "nodes.h"
#import "bytetable.h"

@interface Region: NSObject {
	uint64_t size;
	ByteTable *bytetable;
	Nodes *nodes;
	void *data;
}
-(void) addBytetable: (ByteTable *) bt;
-(void) addNodes: (Nodes *) nd;
-(void *) data;
-(void) free;
@end


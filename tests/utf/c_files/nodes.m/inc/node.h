#import <Foundation/NSObject.h>
#import "red_black_tree.h"

enum {
	TYPE_XIP,
	TYPE_BYTEALIGNED,
	TYPE_COMPRESS
};

@interface Node: NSObject {
	uint8_t type;
}
-(void) numberEntries: (uint64_t) entries type: (uint8_t) type ;
-(void) free;
@end


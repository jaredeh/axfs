#import <Foundation/NSObject.h>
#import "red_black_tree.h"

@interface Region: NSObject {
	uint64_t size;
}
-(void) free;
@end


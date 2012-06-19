#import <Foundation/Foundation.h>
#import "axfs_helper.h"
#import "compressor.h"

extern struct axfs_config acfg;

@interface OptsValidator: NSObject {
}
-(void) initialize;
-(bool) validate;
-(void) free;
@end


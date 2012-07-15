#import <Foundation/Foundation.h>
#import "axfs_helper.h"
#import "compressor.h"

extern struct axfs_config acfg;

@interface OptsValidator: NSObject {
}
-(void) initialize;
-(bool) validate: (char **) msg;
-(void) free;
@end

bool do_opts_validator(char ** msg);


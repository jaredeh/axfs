#import <Foundation/Foundation.h>
#import "axfs_helper.h"
#import "compressor.h"

extern struct axfs_config acfg;

@interface OptsValidator: NSObject {
}
-(int) safe_strlen: (char *) str;
-(bool) is_directory: (char *) path;
-(bool) is_file: (char *) path;
-(bool) validate_properfiles: (char **) msg;
-(bool) validate_compression: (char **) msg;
-(bool) validate_numbers: (char **) msg;
-(bool) validate: (char **) msg;
-(void) free;
@end

bool do_opts_validator(char ** msg);


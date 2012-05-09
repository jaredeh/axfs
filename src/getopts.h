#import <Foundation/NSObject.h>
#import <getopt.h>
#import "axfs_helper.h"

@interface GetOpts: NSObject {
    int argc;
    char ** argv;
    struct axfs_config *config;
}
-(void) input: (char *) opt;
-(void) output: (char *) opt;
-(void) secondary_output: (char *) opt;
-(void) block_size: (char *) opt;
-(void) xip_size: (char *) opt;
-(void) compression: (char *) opt;
-(void) profile: (char *) opt;
-(void) special: (char *) opt;

-(void) argc: (int) c argv: (char **) v;
-(void) config: (struct axfs_config *) f;
-(void) free;
@end

/*
 *********
 -i,--input == input directory
 -o,--output == binary output file, the XIP part
 -d,--secondary_output == second binary output 
 -b,--block_size == compression block size
 -x,--xip_size == xip size of image
 -c,--compression == compression library
 -p,--profile == list of XIP pages
 -s,--special == special modes of execution
 *********
 */

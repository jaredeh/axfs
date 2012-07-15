#import <Foundation/Foundation.h>
#import <getopt.h>
#import "axfs_helper.h"

extern struct axfs_config acfg;

@interface GetOpts: NSObject {
	int argc;
	char ** argv;
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
-(void) initialize;
-(void) free;
@end

void do_getopts(int argc, const char *argv[]);

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

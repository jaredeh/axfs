#import <Foundation/Foundation.h>
#import <getopt.h>
#import "axfs_helper.h"

extern struct axfs_config acfg;

@interface GetOpts: NSObject {
	int argc;
	char ** argv;
}
-(void) dst: (char **) output src: (char *) opt;
-(void) input: (char *) opt;
-(void) output: (char *) opt;
-(void) secondary_output: (char *) opt;
-(void) page_size: (char *) opt;
-(void) block_size: (char *) opt;
-(void) xip_size: (char *) opt;
-(void) compression: (char *) opt;
-(void) profile: (char *) opt;
-(void) special: (char *) opt;
-(bool) is_number: (char) c;
-(uint64_t) char_to_hex: (char) c multi: (uint64_t) i;
-(bool) is_hex: (char *) opt value: (uint64_t *) output;
-(uint64_t) multipliers: (char) c;
-(uint64_t) calc_multiplier: (char *) opt;
-(void) cstring_to_i: (char *) opt dst:(uint64_t *) output;
-(void) convert_arg: (char *) opt dst: (uint64_t *) output;
-(void) switch_long_options: (int) index optarg: (char *) optarg;
-(void) switch_short_options: (int) c index: (int) index optarg: (char *) optarg;
-(void) argc: (int) count argv: (char **) v;
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

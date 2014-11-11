#import "axfs_helper.h"
#import <Foundation/Foundation.h>

extern struct axfs_config acfg;

@interface DirWalker: NSObject {
	uint64_t filename_size;
	uint64_t filedata_size;
	uint64_t number_of_files;
	uint64_t number_of_nodes;
	NSString *rootpath;
}
-(void) file_size: (uint64_t) size file_name: (char *) name;
-(void) size_up_dir;
-(void) walk;
-(void) printstats;
-(void) free;
@end

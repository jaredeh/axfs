#import "axfs_helper.h"
#import <Foundation/Foundation.h>

@interface DirWalker: NSObject {
	uint64_t filename_size;
	uint64_t filedata_size;
	uint64_t number_of_files;
}

-(void) size_up_dir: (NSString *) p;
-(void) initialize;
-(void) free;
@end

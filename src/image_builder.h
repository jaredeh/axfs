#import <Foundation/Foundation.h>
#import "dir_walker.h"
#import "axfs_helper.h"

@interface ImageBuilder: NSObject {
	DirWalker *dw;
}

-(void) build;
-(void) sizeup;
-(void) walk;
-(void) free;
@end


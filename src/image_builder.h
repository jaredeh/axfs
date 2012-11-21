#import <Foundation/Foundation.h>
#import "dir_walker.h"
#import "axfs_helper.h"

@interface ImageBuilder: NSObject {
	DirWalker *dw;
}
-(void) initialize;
-(void) free;
-(void) build;
-(void) sizeup;
-(void) walk;
@end


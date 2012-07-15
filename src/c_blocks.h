#import <Foundation/Foundation.h>
#import "red_black_tree.h"
#import "pages.h"
#import "compressor.h"

@interface CBlocks: NSObject {}

-(void) numberEntries: (uint64_t) e;
-(void *) data;
-(uint64_t) size;
-(uint64_t) length;
-(void) initialize;
-(void) free;

@end

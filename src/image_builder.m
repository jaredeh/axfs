#import "image_builder.h"

@implementation ImageBuilder

-(void) build {

}

-(void) sizeup {
	printf("foo	1\n");
	[dw size_up_dir];
	printf("foo 2\n");
	[dw printstats];
	printf("foo 3\n");
}

-(void) walk {
	[dw walk];
	[dw printstats];

}

-(void) initialize {
	printf("initialize 1\n");
	dw = [[DirWalker alloc] init];
	printf("initialize 2\n");
	[dw initialize];
	printf("initialize 3\n");
}
-(void) free {}
@end


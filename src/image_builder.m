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

-(id) init {
	if (self = [super init]) {
		dw = [[DirWalker alloc] init];
	}
	return self;
}

-(void) free {}
@end


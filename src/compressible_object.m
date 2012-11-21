#import "compressible_object.h"

@implementation CompressibleObject

-(void *) data {
	return NULL;
}

-(uint64_t) size {
	[self data];
	return size;
}

-(void *) cdata {
	Compressor * compressor;
	if (cdata != NULL) {
		return cdata;
	}
	[self data];
	cdata = malloc(size);
	compressor = [[Compressor alloc] init];
	[compressor cdata: cdata csize: &csize data: data size: size];
	[compressor free];
	[compressor release];
	return cdata;
}

-(uint64_t) csize {
	[self cdata];
	return csize;
}

-(id) init {
	if (self = [super init]) {
		data = NULL;
		size = 0;
		cdata = NULL;
		csize = 0;
	}
	return self;
}

@end


@implementation Compressor {
	struct compressor *compress;
	void *stream;
}

-(void) initialize: (char *) name {
	compress = lookup_compressor(name);
	compress->init(&stream, 4096, 0);
}

-(void) cdata: (void *) cdata csize: (uint64_t *) csize data: (void *) data size: (uint64_t) size {
	int error = 0;
	*csize = compress->compress(stream, cdata, data, size, size, &error);
	
}

-(void) free {
}

@end


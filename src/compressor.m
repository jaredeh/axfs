#import "compressor.h"

@implementation Compressor


-(bool) algorithm: (char *) name {
	compress = lookup_compressor(name);
	if(strcmp(compress->name, name) != 0)
		return false;
	compress->init(&stream, 4096, 0);
	return true;
}

-(bool) valid_compressor {
	return valid_compressor;
}

-(id) init {
	if (self = [super init]) {
		valid_compressor = [self algorithm: acfg.compression];
	} 
	return self;
}

-(void) cdata: (void *) cdata csize: (uint64_t *) csize data: (void *) data size: (uint64_t) size {
	int error = 0;

/*
	FILE *fp;
	fp = fopen("data_.bin", "w+");
	fwrite(data,size,1,fp);
	fclose(fp);
*/
/*
	printf("\n1 csize: 0x%08llx\n",(unsigned long long)*csize);
	printf("1 size: 0x%08llx\t%i\n",(unsigned long long)size,(int)size);
	printf("1 data: \t%i\t0x%08llx\t%i\n",(int)data,(unsigned long long)data,(int)data);
	printf("1 cdata: \t%i\t0x%08llx\n",(int)cdata,(unsigned long long)cdata);
*/

	if (size == 0)
		return;

	if (!data)
		[NSException raise: @"Compressor.m" format: @"data == NULL"];
	if (!cdata)
		[NSException raise: @"Compressor.m" format: @"cdata == NULL"];
	if (!csize)
		[NSException raise: @"Compressor.m" format: @"(uint64_t *)csize == NULL"];

	*csize = compress->compress(stream, cdata, data, size, size, &error);

/*
	printf("\n2 csize: 0x%08llx\n",(unsigned long long)*csize);
	printf("2 size: 0x%08llx\n",(unsigned long long)size);
	printf("2 data: \t%i\t0x%08llx\n",(int)data,(unsigned long long)data);
	printf("2 cdata: \t%i\t0x%08llx\n",(int)cdata,(unsigned long long)cdata);
*/
/*
	fp = fopen("data.bin", "w+");
	fwrite(data,size,1,fp);
	fclose(fp);
	fp = fopen("cdata.bin", "w+");
	fwrite(cdata,*csize,1,fp);
	fclose(fp);
*/
	if (error != 0)
		[NSException raise: @"Compressor.m" format: @"error=%d",error];
}

-(void) free {
}

@end


#import "compressor.h"

@implementation Compressor

-(void) initialize {}


-(void) algorithm: (char *) name {
	compress = lookup_compressor(name);
	compress->init(&stream, 4096, 0);
}

-(void) cdata: (void *) cdata csize: (uint64_t *) csize data: (void *) data size: (uint64_t) size {
	int error = 0;
//	FILE *fp;
//	fp = fopen("data_.bin", "w+");
//	fwrite(data,size,1,fp);
//	fclose(fp);

	*csize = compress->compress(stream, cdata, data, size, size, &error);
//	printf("\ncsize: 0x%08llx\n",*csize);
//	printf(" size: 0x%08llx\n",size);
//	printf(" data: \t%i\t0x%08llx\n",data,data);
//	printf("cdata: \t%i\t0x%08llx\n",cdata,cdata);
//	fp = fopen("data.bin", "w+");
//	fwrite(data,size,1,fp);
//	fclose(fp);
//	fp = fopen("cdata.bin", "w+");
//	fwrite(cdata,*csize,1,fp);
//	fclose(fp);
}

-(void) free {
}

@end


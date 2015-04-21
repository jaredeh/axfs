#import <Foundation/Foundation.h>
#import "axfs_helper.h"
#import "compressor.h"
#import "hash_object.h"

extern struct axfs_config acfg;

@interface CompressibleObject: HashObject {
	uint8_t *data;
	uint64_t size;
	uint8_t *cdata;
	uint64_t csize;
}

-(void *) data;
-(uint64_t) size;
-(void *) cdata;
-(uint64_t) csize;
@end

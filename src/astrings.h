#import <Foundation/Foundation.h>
#import "axfs_helper.h"
#import "compressor.h"
#import "compressible_object.h"

#define AXFS_STRINGS_HASHTABLE_SIZE 65535

extern struct axfs_config acfg;

struct string_struct {
	void *data;
	uint64_t length;
	uint64_t position;
	struct string_struct *next;
};

@interface Strings: CompressibleObject {
	struct data_struct strings;
	struct data_struct data_obj;
	uint64_t length;
}
-(struct string_struct *) allocStringStruct;
-(void *) allocStringData: (uint64_t) len;
-(void *) addString: (void *) data_ptr length: (uint64_t) len;
-(void *) data;
-(uint64_t) size;
-(uint64_t) length;
-(void) free;
@end

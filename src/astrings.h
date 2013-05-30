#import <Foundation/Foundation.h>
#import "axfs_helper.h"
#import "compressor.h"
#import "compressible_object.h"
#import "bytetable.h"

extern struct axfs_config acfg;

struct string_struct {
	void *data;
	uint8_t pad;
	uint64_t length;
	uint64_t position;
	struct string_struct *next;
};

@interface Strings: CompressibleObject {
	struct data_struct strings;
	struct data_struct data_obj;
	struct data_struct out_obj;
	ByteTable *nameOffset;
	void **nameOrder;
	uint64_t length;
}
-(struct string_struct *) allocStringStruct;
-(void *) allocStringData: (uint64_t) len;
-(void) nameOrder: (void **) no;
-(void *) addString: (void *) data_ptr length: (uint64_t) len;
-(void *) data;
-(uint64_t) size;
-(uint64_t) length;
-(void) free;
@end

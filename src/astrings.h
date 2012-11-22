#import <Foundation/Foundation.h>
#import "red_black_tree.h"
#import "axfs_helper.h"
#import "compressor.h"
#import "compressible_object.h"

extern struct axfs_config acfg;

struct string_struct {
	void *data;
	uint64_t length;
	rb_red_blk_node rb_node;
};

@interface Strings: CompressibleObject {
	struct data_struct strings;
	struct data_struct data_obj;
	uint64_t length;
}
-(struct string_struct *) allocStringStruct;
-(void *) allocStringData: (uint64_t) len;
-(void) populate: (struct string_struct *) str data: (void *) data_ptr length: (uint64_t) len;
-(void *) addString: (void *) data_ptr length: (uint64_t) len;
-(void *) data;
-(uint64_t) size;
-(uint64_t) length;
-(void) free;
@end

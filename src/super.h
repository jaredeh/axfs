#import <Foundation/Foundation.h>
#import "axfs_helper.h"
#import "axfs_objects.h"
#import "region.h"
#include "linux/axfs_ducttape.h"
#include "linux/axfs_fs.h"

extern struct axfs_config acfg;
extern struct axfs_objects aobj;

#define AXFS_SUPER_SIZE 253

@interface NSObject(SuperMethods)
-(Region *) region;
@end

@interface Super: NSObject {
	void *data;
	uint8_t *data_p;
	struct axfs_super_onmedia *sb;
}
-(id) init;
-(void) do_digest;
/* Identifies type of compression used on FS */
-(void) do_compression_type;
/* UNIX time_t of filesystem build time */
-(void) do_timestamp;
-(void) do_page_shift;
-(uint64_t) size;
-(void *) data;
-(void) free;

@end

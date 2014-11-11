#import <Foundation/Foundation.h>
#import "axfs_helper.h"
#import "btree_object.h"
#import "compressor.h"

#define AXFS_PAGES_HASHTABLE_SIZE 65535

extern struct axfs_config acfg;

struct page_struct {
	void *data;
	uint64_t length;
	void *cdata;
	uint64_t clength;
	struct page_struct *next;
};

@interface Pages: BtreeObject {
	struct data_struct pages;
	struct data_struct data;
	struct data_struct cdata;
	uint64_t length;
	Compressor * compressor;
}
-(struct page_struct *) allocPageStruct;
-(void *) allocPageData;
-(void *) allocPageCdata;
-(void *) addPage: (void *) data_ptr length: (uint64_t) len;
-(void) free;
@end

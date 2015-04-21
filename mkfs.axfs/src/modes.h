#import <Foundation/Foundation.h>
#import "hash_object.h"
#import "axfs_helper.h"
#import "axfs_objects.h"
#import "bytetable.h"
#include <sys/stat.h>

extern struct axfs_config acfg;
extern struct axfs_objects aobj;

#define AXFS_MODES_HASHTABLE_SIZE 65535

struct mode_struct {
	uint32_t gid;
	uint32_t uid;
	uint32_t mode;
	uint64_t position;
	struct mode_struct *next;
};

@interface Modes: HashObject {
	struct data_struct modes;
	ByteTable *modesTable;
	ByteTable *uids;
	ByteTable *gids;
}
-(void *) addMode: (struct stat *) sb;
-(uint64_t) length;
-(id) modesTable;
-(id) uids;
-(id) gids;
-(void *) data;
-(void) free;
@end

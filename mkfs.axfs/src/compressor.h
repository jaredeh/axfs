#import <Foundation/Foundation.h>
#import "axfs_helper.h"

extern struct axfs_config acfg;

struct compressor {
	int (*init)(void **, int, int);
	int (*compress)(void *, void *, void *, int, int, int *);
	int (*uncompress)(void *, void *, int, int, int *);
	int (*options)(char **, int);
	int (*options_post)(int);
	void *(*dump_options)(int, int *);
	int (*extract_options)(int, void *, int);
	void (*usage)();
	int id;
	char *name;
	int supported;
};

extern struct compressor *compressor[];
extern struct compressor *lookup_compressor(char *name);

@interface Compressor: NSObject {
	struct compressor *compress;
	void *stream;
	bool valid_compressor;
}
-(bool) algorithm: (char *) name;
-(bool) valid_compressor;
-(void) cdata: (void *) cdata csize: (uint64_t *) csize data: (void *) data size: (uint64_t) size;
-(void) free;
@end


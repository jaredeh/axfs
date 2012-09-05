#import <Foundation/Foundation.h>
#import "nodes.h"
#import "bytetable.h"

@interface Region: NSObject {
	uint64_t size;
	ByteTable *bytetable;
	Nodes *nodes;
	void *data;
	uint8_t *data_p;
	uint64_t fsoffset;
	uint8_t incore;
}
-(void) addBytetable: (ByteTable *) bt;
-(void) addNodes: (Nodes *) nd;
-(uint8_t *) data_p;
-(void *) data;
-(void) fsoffset: (uint64_t) offset;
-(void) incore: (uint8_t) core;
-(void *) get_data;
-(void *) get_cdata;
-(uint64_t) get_size;
-(uint64_t) get_csize;
-(uint64_t) get_max_index;
-(uint8_t) get_table_byte_depth;
-(uint8_t) output_byte: (uint64_t) datum shift: (uint64_t) i;
-(void) big_endian_64: (uint64_t) number;
-(void) big_endian_32: (uint32_t) number;
-(void) big_endian_byte: (uint8_t) number;
-(void) initialize;
-(void) free;
@end


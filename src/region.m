#import "region.h"

@implementation Region

-(void) addBytetable: (ByteTable *) bt {
	bytetable = bt;
}

-(void) addNodes: (Nodes *) nd {
	nodes = nd;
}

/* on media struct describing a data region */
//struct axfs_region_desc_onmedia {
//	u64 fsoffset;
//	u64 size;
//	u64 compressed_size;
//	u64 max_index;
//	u8 table_byte_depth;
//	u8 incore;
//};

-(uint8_t *) data_p {
	return data;
}

-(void *) data {
	uint64_t lsize;
	uint64_t csize;
	uint64_t max_index;
	uint8_t table_byte_depth;

	lsize = [self get_size];
	csize = [self get_csize];
	max_index = [self get_max_index];
	table_byte_depth = [self get_table_byte_depth];

	[self big_endian_64: fsoffset];
	[self big_endian_64: lsize];
	[self big_endian_64: csize];
	[self big_endian_64: max_index];
	[self big_endian_byte: table_byte_depth];
	[self big_endian_byte: incore];

	return data;
}

-(void) fsoffset: (uint64_t) offset {
	fsoffset = offset;
}

-(void) incore: (uint8_t) core {
	incore = core;
}

-(void *) get_data {
	if (nodes == NULL)
		return [bytetable data];
	return [nodes data];
}

-(void *) get_cdata {
	if (nodes == NULL)
		return [bytetable cdata];
	return [nodes cdata];
}

-(uint64_t) get_size {
	if (nodes == NULL)
		return [bytetable size];
	return [nodes size];
}

-(uint64_t) get_csize {
	if (nodes == NULL)
		return [bytetable csize];
	return [nodes csize];
}

-(uint64_t) get_max_index {
	if (nodes == NULL)
		return [bytetable length];
	return [nodes length];
}

-(uint8_t) get_table_byte_depth {
	if (nodes == NULL)
		return [bytetable depth];
	return 0;
}

-(uint8_t) output_byte: (uint64_t) datum shift: (uint64_t) i {
	uint64_t mask;
	uint64_t byte;

	mask = 0xFFUL << (i*8);
	//printf("\ni:    0x%016llx\n",(long long unsigned int)i);
	//printf("mask: 0x%016llx\n",(long long unsigned int)mask);
	byte = datum & mask;
	//printf("0byte:0x%016llx\n",(long long unsigned int)byte);
	byte = byte >> (i*8);
	//printf("1byte:0x%016llx\n",(long long unsigned int)byte);
	return (uint8_t) byte;
}

-(void) big_endian_64: (uint64_t) number {
	int i;

	for(i=0; i<8; i++) {
		data_p[7-i] = [self output_byte: number shift: i];
	}
	//i++;
	data_p += i;
}

-(void) big_endian_32: (uint32_t) number {
	int i;

	for(i=0; i<4; i++) {
		data_p[3-i] = [self output_byte: number shift: i];
	}
	i++;
	data_p += i;
}

-(void) big_endian_byte: (uint8_t) number {
	data_p[0] = number;
	data_p += 1;
}

-(void) initialize {
	fsoffset = 0;
	nodes = NULL;
	bytetable = NULL;
	data = malloc(8*4 + 1 + 1);
	memset(data,0,8*4 + 1 + 1);
	data_p = data;
}

-(void) free {
	free(data);
}

@end


#import "region_descriptors.h"

@implementation RegionDescriptors

-(void) fsalign: (uint64_t) align {
	fsalign = align;
}

-(void) fsoffset: (uint64_t) offset {
	fsoffset = [self alignNumber: offset bytes: fsalign];
}

-(uint64_t) fsoffset {
	return fsoffset;
}

-(id) init {
	if (!(self = [super init]))
		return self;

	size = sizeof(struct axfs_region_desc_onmedia) * 18;
	data = malloc(size);
	return self;
}

-(uint64_t) setRegionFsoffset: (Region *) r fsoffset: (uint64_t) offset {
	uint64_t end;
	[r fsoffset: offset];
	end = [r fsoffset];
	end += [r size];
	return end;
}

-(uint64_t) regionOffsets {
	struct axfs_region_descriptors *r = &aobj.regions;
	uint64_t offset = fsoffset;

	offset = [self setRegionFsoffset: r->strings fsoffset: offset];
	offset = [self setRegionFsoffset: r->xip fsoffset: offset];
	offset = [self setRegionFsoffset: r->byte_aligned fsoffset: offset];
	offset = [self setRegionFsoffset: r->compressed fsoffset: offset];
	offset = [self setRegionFsoffset: r->node_type fsoffset: offset];
	offset = [self setRegionFsoffset: r->node_index fsoffset: offset];
	offset = [self setRegionFsoffset: r->cnode_offset fsoffset: offset];
	offset = [self setRegionFsoffset: r->cnode_index fsoffset: offset];
	offset = [self setRegionFsoffset: r->banode_offset fsoffset: offset];
	offset = [self setRegionFsoffset: r->cblock_offset fsoffset: offset];
	offset = [self setRegionFsoffset: r->inode_file_size fsoffset: offset];
	offset = [self setRegionFsoffset: r->inode_name_offset fsoffset: offset];
	offset = [self setRegionFsoffset: r->inode_num_entries fsoffset: offset];
	offset = [self setRegionFsoffset: r->inode_mode_index fsoffset: offset];
	offset = [self setRegionFsoffset: r->inode_array_index fsoffset: offset];
	offset = [self setRegionFsoffset: r->modes fsoffset: offset];
	offset = [self setRegionFsoffset: r->uids fsoffset: offset];
	offset = [self setRegionFsoffset: r->gids fsoffset: offset];
	return offset;
}

-(void) processRegion: (Region *) r {
	printf("processRegion r %x\n",r);
	void *src = [r data];
	printf("data\n");
	size_t len = [r size];
	printf("len = %i\n",len);
	memcpy(data_p, src, len);
	printf("data_p = 0x%08x\n",data_p);
	data_p += len;
}

-(uint64_t) size {
	return size;
}

-(void *) data {
	struct axfs_region_descriptors *r = &aobj.regions;

	data_p = data;
	printf("[RegionDescriptors data] 0\n");
	[self regionOffsets];
	printf("[RegionDescriptors data] 1\n");

	[self processRegion: r->strings];
	printf("[RegionDescriptors data] 2\n");
	[self processRegion: r->xip];
	printf("[RegionDescriptors data] 3\n");
	[self processRegion: r->byte_aligned];
	printf("[RegionDescriptors data] 4\n");
	[self processRegion: r->compressed];
	printf("[RegionDescriptors data] 5\n");
	[self processRegion: r->node_type];
	printf("[RegionDescriptors data] 6\n");
	[self processRegion: r->node_index];
	printf("[RegionDescriptors data] 7\n");
	[self processRegion: r->cnode_offset];
	printf("[RegionDescriptors data] 8\n");
	[self processRegion: r->cnode_index];
	printf("[RegionDescriptors data] 9\n");
	[self processRegion: r->banode_offset];
	printf("[RegionDescriptors data] 10\n");
	[self processRegion: r->cblock_offset];
	printf("[RegionDescriptors data] 11\n");
	[self processRegion: r->inode_file_size];
	printf("[RegionDescriptors data] 12\n");
	[self processRegion: r->inode_name_offset];
	printf("[RegionDescriptors data] 13\n");
	[self processRegion: r->inode_num_entries];
	printf("[RegionDescriptors data] 14\n");
	[self processRegion: r->inode_mode_index];
	printf("[RegionDescriptors data] 15\n");
	[self processRegion: r->inode_array_index];
	printf("[RegionDescriptors data] 16\n");
	[self processRegion: r->modes];
	printf("[RegionDescriptors data] 17\n");
	[self processRegion: r->uids];
	printf("[RegionDescriptors data] 18\n");
	[self processRegion: r->gids];
	printf("[RegionDescriptors data] 19\n");

	if ((data_p - (uint8_t *)data) > size)
		[NSException raise: @"Too big " format: @"(data_p[%d] - data[%d]=%d) > size[%d]",data_p,data,(int)data_p-(int)data,size];
	printf("[RegionDescriptors data] 3\n");

	return data;
}

-(void) free {
	free(data);
}

@end
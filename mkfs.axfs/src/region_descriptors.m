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
	void *src = [r data];
	size_t len = [r size];
	memcpy(data_p, src, len);
	data_p += len;
}

-(uint64_t) size {
	return size;
}

-(void *) data {
	struct axfs_region_descriptors *r = &aobj.regions;

	data_p = data;
	[self regionOffsets];

	[self processRegion: r->strings];
	[self processRegion: r->xip];
	[self processRegion: r->byte_aligned];
	[self processRegion: r->compressed];
	[self processRegion: r->node_type];
	[self processRegion: r->node_index];
	[self processRegion: r->cnode_offset];
	[self processRegion: r->cnode_index];
	[self processRegion: r->banode_offset];
	[self processRegion: r->cblock_offset];
	[self processRegion: r->inode_file_size];
	[self processRegion: r->inode_name_offset];
	[self processRegion: r->inode_num_entries];
	[self processRegion: r->inode_mode_index];
	[self processRegion: r->inode_array_index];
	[self processRegion: r->modes];
	[self processRegion: r->uids];
	[self processRegion: r->gids];

	if ((data_p - (uint8_t *)data) > size) {
		[NSException raise: @"Too big " format: @"(data_p[%d] - data[%d]=%d) > size[%d]",data_p,data,(uint64_t)data_p-(uint64_t)data,size];
	}

	return data;
}

-(void) free {
	free(data);
}

@end
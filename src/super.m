#import "super.h"

@implementation Super

-(id) init {
	if (!(self = [super init]))
		return self;

	data = malloc(AXFS_SUPER_SIZE);
	data_p = data;
	sb = (struct axfs_super_onmedia *) data;

	return self;
}

-(void) processRegion: (Region *) r ptr: (void *) ptr {
	[self bigEndian64: [r fsoffset] ptr: ptr];
}

-(void) do_magic {
	uint32_t magic = AXFS_MAGIC;
	[self bigEndian32: magic ptr: &sb->magic];
}

/* sha1 digest for checking data integrity */
-(void) do_digest: (unsigned char *) hash {
	memcpy((void *)sb->digest,(void *)hash,40);
}

/* Identifies type of compression used on FS */
-(void) do_compression_type {

}

/* UNIX time_t of filesystem build time */
-(void) do_timestamp {
	uint32_t ts =0;
	[self bigEndian32: ts ptr: &sb->timestamp];
}

-(void) do_page_shift {
	uint64_t page_shift;

	page_shift = log2(acfg.page_size);
	sb->page_shift = (uint8_t) page_shift;
}

-(uint64_t) size {
	return sizeof(*sb);
}

-(void *) data {
	struct axfs_region_descriptors *r = &aobj.regions;

	[self do_magic];

	memcpy(sb->signature, AXFS_SIGNATURE, strlen(AXFS_SIGNATURE));

	[self bigEndian64: acfg.block_size ptr: &sb->cblock_size];
	[self bigEndian64: acfg.real_number_files ptr: &sb->files];
	[self bigEndian64: acfg.real_imagesize ptr: &sb->size];
	[self bigEndian64: acfg.real_number_nodes ptr: &sb->blocks];
	[self bigEndian64: acfg.mmap_size ptr: &sb->mmap_size];

	[self processRegion: r->strings ptr: &sb->strings];
	[self processRegion: r->xip ptr: &sb->xip];
	[self processRegion: r->byte_aligned ptr: &sb->byte_aligned];
	[self processRegion: r->compressed ptr: &sb->compressed];
	[self processRegion: r->node_type ptr: &sb->node_type];
	[self processRegion: r->node_index ptr: &sb->node_index];
	[self processRegion: r->cnode_offset ptr: &sb->cnode_offset];
	[self processRegion: r->cnode_index ptr: &sb->cnode_index];
	[self processRegion: r->banode_offset ptr: &sb->banode_offset];
	[self processRegion: r->cblock_offset ptr: &sb->cblock_offset];
	[self processRegion: r->inode_file_size ptr: &sb->inode_file_size];
	[self processRegion: r->inode_name_offset ptr: &sb->inode_name_offset];
	[self processRegion: r->inode_num_entries ptr: &sb->inode_num_entries];
	[self processRegion: r->inode_mode_index ptr: &sb->inode_mode_index];
	[self processRegion: r->inode_array_index ptr: &sb->inode_array_index];
	[self processRegion: r->modes ptr: &sb->modes];
	[self processRegion: r->uids ptr: &sb->uids];
	[self processRegion: r->gids ptr: &sb->gids];

	sb->version_major = acfg.version_major;
	sb->version_minor = acfg.version_minor;
	sb->version_sub = acfg.version_sub;

	[self do_compression_type];
	[self do_timestamp];
	[self do_page_shift];
	return data;
}

-(void) free {
	free(data);
}

@end

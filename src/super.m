@implementation Super

-(id) init {
	self = [super init];
	data = malloc(500);
	data_p = data;
	return self;
}

-(void) do_magic {
	*(data_p++) = 0x48;
	*(data_p++) = 0xA0;
	*(data_p++) = 0xE4;
	*(data_p++) = 0xCD;
}

-(void) do_signature {
	void *signature = "Advanced XIP FS\0";
	memcpy(data_p, signature, strlen(signature));
	data_p += 16;
}

/* sha1 digest for checking data integrity */
-(void) do_digest {
	data_p += 40;
}

/* maximum size of the block being compressed */
-(void) do_cblock_size {
}

/* number of inodes/files in fs */
-(void) do_files {
}

/* total image size */
-(void) do_size {
}

/* number of nodes in fs */
-(void) do_blocks {
}

/* size of the memory mapped part of image */
-(void) do_mmap_size {
}

/* offset to strings region descriptor */
-(void) do_strings {
}

/* offset to xip region descriptor */
-(void) do_xip {
}

/* offset to the byte aligned region desc */
-(void) do_byte_aligned {
}

/* offset to the compressed region desc */
-(void) do_compressed {
}

/* offset to node type region desc */
-(void) do_node_type {
}

/* offset to node index region desc */
-(void) do_node_index {
}

/* offset to cnode offset region desc */
-(void) do_cnode_offset {
}

/* offset to cnode index region desc */
-(void) do_cnode_index {
}

/* offset to banode offset region desc */
-(void) do_banode_offset {
}

/* offset to cblock offset region desc */
-(void) do_cblock_offset {
}

/* offset to inode file size desc */
-(void) do_inode_file_size {
}

/* offset to inode num_entries region desc */
-(void) do_inode_name_offset {
}

/* offset to inode num_entries region desc */
-(void) do_inode_num_entries {
}

/* offset to inode mode index region desc */
-(void) do_inode_mode_index {
}

/* offset to inode node index region desc */
-(void) do_inode_array_index {
}

/* offset to mode mode region desc */
-(void) do_modes {
}

/* offset to mode uid index region desc */
-(void) do_uids {
}

/* offset to mode gid index region desc */
-(void) do_gids {
}

-(void) do_version_major {
}

-(void) do_version_minor {
}

-(void) do_version_sub {
}

/* Identifies type of compression used on FS */
-(void) do_compression_type {
}

/* UNIX time_t of filesystem build time */
-(void) do_timestamp {
}

-(void) do_page_shift {
}

-(void) cblock_size: (uint32_t) cbs {
}

-(uint64_t) size {
	return 253;
}

-(void *) data {
	[self do_magic];
	[self do_signature];
	[self do_digest];
	[self do_cblock_size];
	[self do_files];
	[self do_size];
	[self do_blocks];
	[self do_mmap_size];
	[self do_strings];
	[self do_xip];
	[self do_byte_aligned];
	[self do_compressed];
	[self do_node_type];
	[self do_node_index];
	[self do_cnode_offset];
	[self do_cnode_index];
	[self do_banode_offset];
	[self do_cblock_offset];
	[self do_inode_file_size];
	[self do_inode_name_offset];
	[self do_inode_num_entries];
	[self do_inode_mode_index];
	[self do_inode_array_index];
	[self do_modes];
	[self do_uids];
	[self do_gids];
	[self do_version_major];
	[self do_version_minor];
	[self do_version_sub];
	[self do_compression_type];
	[self do_timestamp];
	[self do_page_shift];
	return data;
}

-(void) free {
	free(data);
}

@end

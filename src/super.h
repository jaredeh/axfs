#import <Foundation/Foundation.h>
#import "axfs_helper.h"

@interface Super: NSObject {
	void *data;
	uint8_t *data_p;
	uint32_t cblock_size;
}
-(id) init;
-(void) do_magic;
-(void) do_signature;
-(void) do_digest;
-(void) do_cblock_size;
-(void) do_files;
-(void) do_size;
-(void) do_blocks;
-(void) do_mmap_size;

/* offset to strings region descriptor */
-(void) do_strings;
/* offset to xip region descriptor */
-(void) do_xip;
/* offset to the byte aligned region desc */
-(void) do_byte_aligned;
/* offset to the compressed region desc */
-(void) do_compressed;
/* offset to node type region desc */
-(void) do_node_type;
/* offset to node index region desc */
-(void) do_node_index;
/* offset to cnode offset region desc */
-(void) do_cnode_offset;
/* offset to cnode index region desc */
-(void) do_cnode_index;
/* offset to banode offset region desc */
-(void) do_banode_offset;
/* offset to cblock offset region desc */
-(void) do_cblock_offset;
/* offset to inode file size desc */
-(void) do_inode_file_size;
/* offset to inode num_entries region desc */
-(void) do_inode_name_offset;
/* offset to inode num_entries region desc */
-(void) do_inode_num_entries;
/* offset to inode mode index region desc */
-(void) do_inode_mode_index;
/* offset to inode node index region desc */
-(void) do_inode_array_index;
/* offset to mode mode region desc */
-(void) do_modes;
/* offset to mode uid index region desc */
-(void) do_uids;
/* offset to mode gid index region desc */
-(void) do_gids;
-(void) do_version_major;
-(void) do_version_minor;
-(void) do_version_sub;
/* Identifies type of compression used on FS */
-(void) do_compression_type;
/* UNIX time_t of filesystem build time */
-(void) do_timestamp;
-(void) do_page_shift;
-(void) cblock_size: (uint32_t) cbs;
-(uint64_t) size;
-(void *) data;
-(void) free;

@end

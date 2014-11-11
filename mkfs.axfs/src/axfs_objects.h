
struct axfs_region_descriptors {
	id strings;
	id xip;
	id byte_aligned;
	id compressed;
	id node_type;
	id node_index;
	id cnode_offset;
	id cnode_index;
	id banode_offset;
	id cblock_offset;
	id inode_file_size;
	id inode_name_offset;
	id inode_num_entries;
	id inode_mode_index;
	id inode_array_index;
	id modes;
	id uids;
	id gids;
};

struct axfs_objects {
	id strings;
	id nodes;
	id xip;
	id byte_aligned;
	id compressed;
	//type
	//index
	id inodes;
	id modes;
	id dirwalker;
	id superblock;
	id regdesc;
	id pages;
	struct axfs_region_descriptors regions;
};

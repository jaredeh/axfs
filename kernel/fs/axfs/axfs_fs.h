/*
 * Advanced XIP File System for Linux - AXFS
 *   Readonly, compressed, and XIP filesystem for Linux systems big and small
 *
 * Copyright(c) 2008 Numonyx
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms and conditions of the GNU General Public License,
 * version 2, as published by the Free Software Foundation.
 *
 * Authors:
 *  Eric Anderson
 *  Jared Hulbert <jaredeh@gmail.com>
 *  Sujaya Srinivasan
 *  Justin Treon
 *
 * Project url: http://axfs.sourceforge.net
 */

#ifndef AXFS_FS_H
#define AXFS_FS_H

#include "axfs_fs_sb.h"

#ifndef ALL_VERSIONS
#include <linux/version.h>	/* For multi-version support */
#endif

#ifdef __KERNEL__
#include <linux/rwsem.h>
#endif
#include <linux/errno.h>
#include <linux/time.h>

#include <linux/pagemap.h>
#include <linux/fs.h>
#include <linux/mount.h>

#define AXFS_MAGIC	0x48A0E4CD	/* some random number */
#define AXFS_SIGNATURE	"Advanced XIP FS"
#define AXFS_MAXPATHLEN 255

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,18)
#else
#define false 0
#define true 1
#endif

enum axfs_node_types {
	XIP = 0,
	Compressed,
	Byte_Aligned,
};

enum axfs_compression_types {
	ZLIB = 0
};

/* on media struct describing a data region */
struct axfs_region_desc_onmedia {
	u64 fsoffset;
	u64 size;
	u64 compressed_size;
	u64 max_index;
	u8 table_byte_depth;
	u8 incore;
};

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,10)
#else
struct axfs_fill_super_info {
	struct axfs_super_onmedia *onmedia_super_block;
	unsigned long physical_start_address;
	unsigned long virtual_start_address;
};
#endif

/* on media format for the super block */
struct axfs_super_onmedia {
	__be32 magic;		/* 0x48A0E4CD - random number */
	u8 signature[16];	/* "Advanced XIP FS" */
	u8 digest[40];		/* sha1 digest for checking data integrity */
	__be32 cblock_size;	/* maximum size of the block being compressed */
	__be64 files;		/* number of inodes/files in fs */
	__be64 size;		/* total image size */
	__be64 blocks;		/* number of nodes in fs */
	__be64 mmap_size;	/* size of the memory mapped part of image */
	__be64 strings;		/* offset to strings region descriptor */
	__be64 xip;		/* offset to xip region descriptor */
	__be64 byte_aligned;	/* offset to the byte aligned region desc */
	__be64 compressed;	/* offset to the compressed region desc */
	__be64 node_type;	/* offset to node type region desc */
	__be64 node_index;	/* offset to node index region desc */
	__be64 cnode_offset;	/* offset to cnode offset region desc */
	__be64 cnode_index;	/* offset to cnode index region desc */
	__be64 banode_offset;	/* offset to banode offset region desc */
	__be64 cblock_offset;	/* offset to cblock offset region desc */
	__be64 inode_file_size;	/* offset to inode file size desc */
	__be64 inode_name_offset;	/* offset to inode num_entries region desc */
	__be64 inode_num_entries;	/* offset to inode num_entries region desc */
	__be64 inode_mode_index;	/* offset to inode mode index region desc */
	__be64 inode_array_index;	/* offset to inode node index region desc */
	__be64 modes;		/* offset to mode mode region desc */
	__be64 uids;		/* offset to mode uid index region desc */
	__be64 gids;		/* offset to mode gid index region desc */
	u8 version_major;
	u8 version_minor;
	u8 version_sub;
	u8 compression_type;	/* Identifies type of compression used on FS */
	__be64 timestamp;	/* UNIX time_t of filesystem build time */
	u8 page_shift;
};

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,5,0)
#define AXFS_SB(sb) ((struct axfs_super *)((sb)->s_fs_info))
#else
#define AXFS_SB(sb) ((struct axfs_super *) &((sb)->u.axfs_sb))
#endif

static inline u64 axfs_bytetable_stitch(u8 depth, u8 *table, u64 index)
{
	u64 i;
	u64 output = 0;
	u64 byte = 0;
	u64 j;
	u64 bits;

	for (i = 0; i < depth; i++) {
		j = index * depth + i;
		bits = 8 * (depth - i - 1);
		byte = table[j];
		output += byte << bits;
	}
	return output;
}
#endif

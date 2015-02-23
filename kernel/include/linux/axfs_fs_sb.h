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
 * Project url: https://code.google.com/p/axfs/
 */

#ifndef AXFS_FS_SB_H
#define AXFS_FS_SB_H

#ifndef ALL_VERSIONS
#include <linux/version.h>	/* For multi-version support */
#endif

#ifdef __KERNEL__
#include <linux/rwsem.h>
#endif
#include <linux/errno.h>
#include <linux/time.h>

/* in memory region descriptor */
struct axfs_region_desc {
	u64 fsoffset;
	u64 size;
	u64 compressed_size;
	u64 max_index;
	void *virt_addr;
	u8 table_byte_depth;
	u8 incore;
};

/* axfs super-block data in memory */
struct axfs_super {
	u32 magic;
	u8 version_major;
	u8 version_minor;
	u8 version_sub;
	u8 padding;
	u64 files;
	u64 size;
	u64 blocks;
	u64 mmap_size;
	struct axfs_region_desc strings;
	struct axfs_region_desc xip;
	struct axfs_region_desc compressed;
	struct axfs_region_desc byte_aligned;
	struct axfs_region_desc node_type;
	struct axfs_region_desc node_index;
	struct axfs_region_desc cnode_offset;
	struct axfs_region_desc cnode_index;
	struct axfs_region_desc banode_offset;
	struct axfs_region_desc cblock_offset;
	struct axfs_region_desc inode_file_size;
	struct axfs_region_desc inode_name_offset;
	struct axfs_region_desc inode_num_entries;
	struct axfs_region_desc inode_mode_index;
	struct axfs_region_desc inode_array_index;
	struct axfs_region_desc modes;
	struct axfs_region_desc uids;
	struct axfs_region_desc gids;
	unsigned long phys_start_addr;
	unsigned long virt_start_addr;
	char *second_dev;
	unsigned long iomem_size;
	void *mtd0;		/* primary device */
	void *mtd1;		/* secondary device */
	u32 cblock_size;
	u64 current_cnode_index;
	void *cblock_buffer[2];
	struct rw_semaphore lock;
	u8 profiling_on;	/* Determines if profiling is on or off */
	u8 mtd_pointed;
	u8 compression_type;
	struct timespec timestamp;
	u8 page_shift;
	void *profile_man;
};

#endif

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

#ifndef AXFS_H
#define AXFS_H

#include <linux/axfs_fs.h>
#include <linux/axfs_fs_sb.h>

#include <linux/pagemap.h>
#include <linux/fs.h>
#include <linux/mount.h>

/* axfs_inode.c */
struct inode *axfs_create_vfs_inode(struct super_block *, int);
u64 axfs_get_mode(struct axfs_super *sbi, u64 index);
u64 axfs_get_uid(struct axfs_super *sbi, u64 index);
u64 axfs_get_gid(struct axfs_super *sbi, u64 index);
u64 axfs_get_inode_name_offset(struct axfs_super *sbi, u64 index);
u64 axfs_get_inode_num_entries(struct axfs_super *sbi, u64 index);
u64 axfs_get_inode_mode_index(struct axfs_super *sbi, u64 index);
u64 axfs_get_inode_array_index(struct axfs_super *sbi, u64 index);
char *axfs_get_inode_name(struct axfs_super *sbi, u64 index);

/* axfs_super.c */
u64 axfs_get_io_dev_size(struct super_block *sb);
int axfs_fill_super(struct super_block *sb, void *data, int silent);
int axfs_get_sb(struct file_system_type *, int, const char *, void *,
		struct vfsmount *);
int axfs_physaddr_is_valid(struct axfs_super *sbi);
int axfs_virtaddr_is_valid(struct axfs_super *sbi);
int axfs_is_iomem(struct axfs_super *sbi);
int axfs_is_pointed(struct axfs_super *sbi);
int axfs_can_xip(struct axfs_super *sbi);
int axfs_is_physmem(struct axfs_super *sbi);
int axfs_nodev(struct super_block *sb);
u64 axfs_fsoffset_to_devoffset(struct axfs_super *sbi, u64 fsoffset);

/* axfs_profiling.c */
void axfs_profiling_add(struct axfs_super *, unsigned long, unsigned int);
int axfs_init_profiling(struct axfs_super *);
int axfs_shutdown_profiling(struct axfs_super *);

/* axfs_mtd.c */
int axfs_copy_mtd(struct super_block *, void *, u64, u64);
int axfs_get_sb_mtd(struct file_system_type *, int, const char *,
		    struct axfs_super *, struct vfsmount *, int *);
void axfs_kill_mtd_super(struct super_block *);
int axfs_is_dev_mtd(char *, int *);
int axfs_verify_mtd_sizes(struct super_block *sb, int *err);
int axfs_map_mtd(struct super_block *);
void axfs_unmap_mtd(struct super_block *);
struct mtd_info *axfs_mtd(struct super_block *sb);
struct mtd_info *axfs_mtd0(struct super_block *sb);
struct mtd_info *axfs_mtd1(struct super_block *sb);
int axfs_has_mtd(struct super_block *sb);

/* axfs_bdev.c */
void axfs_copy_block(struct super_block *, void *, u64, u64);
int axfs_get_sb_bdev(struct file_system_type *, int, const char *,
		     struct axfs_super *, struct vfsmount *, int *);
void axfs_kill_block_super(struct super_block *);
int axfs_is_dev_bdev(char *);
int axfs_verify_bdev_sizes(struct super_block *sb, int *err);
struct block_device *axfs_bdev(struct super_block *sb);
int axfs_has_bdev(struct super_block *sb);

/* axfs_uml.c */
int axfs_get_uml_address(char *, unsigned long *, unsigned long *);

#ifndef NO_PHYSMEM
/* axfs_physmem.c */
void axfs_map_physmem(struct axfs_super *, unsigned long);
void axfs_unmap_physmem(struct super_block *);
#endif

#endif

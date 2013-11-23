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
 *  Jared Hulbert <jaredeh@gmail.com>
 *
 * Project url: http://axfs.sourceforge.net
 *
 * axfs_mtd.c -
 *   Allows axfs to use mtd devices or has dummy functions if mtd
 *   device support is compiled out of the kernel.
 */
#include "axfs.h"

#include <linux/fs.h>
#include <linux/mount.h>
#include <linux/ctype.h>
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,5,0)
#include <linux/namei.h>

#ifdef CONFIG_MTD
#define AXFS_CONFIG_MTD
#endif
#else
#endif

#ifdef AXFS_CONFIG_MTD
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,21)
#include <linux/mtd/super.h>
#else
#include <linux/mtd/mtd.h>
#endif
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,9)
#else
#define OLD_POINT 1
#endif

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,21)
struct mtd_info *axfs_mtd(struct super_block *sb)
{
	return (void *)sb->s_mtd;
}
#else
struct mtd_info *axfs_mtd(struct super_block *sb)
{
	return NULL;
}
#endif

struct mtd_info *axfs_mtd0(struct super_block *sb)
{
	struct axfs_super *sbi = AXFS_SB(sb);

	if (sbi->mtd0 != NULL)
		return sbi->mtd0;
	else
		return axfs_mtd(sb);
}

struct mtd_info *axfs_mtd1(struct super_block *sb)
{
	struct axfs_super *sbi = AXFS_SB(sb);

	return sbi->mtd1;
}

int axfs_has_mtd(struct super_block *sb)
{
	if (axfs_mtd0(sb))
		return true;

	if (axfs_mtd1(sb))
		return true;

	if (axfs_mtd(sb))
		return true;

	return false;
}

struct mtd_info *axfs_get_mtd_device(int mtdnr)
{
	struct mtd_info *device;

	device = get_mtd_device(NULL, mtdnr);

	if (!PTR_ERR(device))
		return NULL;

	return device;
}

int axfs_is_dev_mtd(char *path, int *mtdnr)
{
	char *off = NULL;
	char *endptr = NULL;
	char dev[] = "/dev/\0";
	char mtd[] = "mtd\0";
	char mtdblk[] = "mtdblock\0";

	if (!path || !*path)
		return false;

	off = path;

	if (strncmp(dev, off, strlen(dev)) == 0)
		off += strlen(dev);

	if (!strncmp(mtd, off, strlen(mtd)) && isdigit(off[strlen(mtd)]))
		off += strlen(mtd);

	if (!strncmp(mtdblk, off, strlen(mtdblk))
	    && isdigit(off[strlen(mtdblk)]))
		off += strlen(mtdblk);

	*mtdnr = simple_strtoul(off, &endptr, 0);

	if (!*endptr)
		return true;

	return false;
}

static struct mtd_info *axfs_get_mtd_info(struct super_block *sb, u64 fsoffset)
{
	struct axfs_super *sbi = AXFS_SB(sb);

	if (fsoffset == 0)
		return (struct mtd_info *)axfs_mtd0(sb);

	if (fsoffset < sbi->mmap_size)
		return (struct mtd_info *)axfs_mtd0(sb);

	if (axfs_mtd1(sb) != NULL)
		return (struct mtd_info *)axfs_mtd1(sb);

	return (struct mtd_info *)axfs_mtd0(sb);
}

int axfs_copy_mtd(struct super_block *sb, void *dst, u64 fsoffset, u64 len)
{
	struct axfs_super *sbi = AXFS_SB(sb);
	u64 offset = axfs_fsoffset_to_devoffset(sbi, fsoffset);
	struct mtd_info *mtd;
	u_char *mtdbuf = (u_char *) dst;
	size_t retlen;
	int err = 0;

	if (len == 0)
		return 0;

	mtd = axfs_get_mtd_info(sb, fsoffset);
	err = mtd->read(mtd, (loff_t) offset, (size_t) len, &retlen, mtdbuf);

	if (len != retlen)
		return -EIO;

	return err;
}

/******************************************************************************
 *
 * axfs_map_mtd
 *
 * Description: When provided, uses the mtd point() capability to map allow
 *	      axfs a direct memory access to the filesystem.
 *
 * Parameters:
 *    (IN) sb - pointer to the super_block structure
 *
 * Returns:
 *    0 or error number
 *
 *****************************************************************************/
int axfs_map_mtd(struct super_block *sb)
{
	struct axfs_super *sbi = AXFS_SB(sb);
	struct mtd_info *mtd = (struct mtd_info *)axfs_mtd0(sb);
	size_t retlen;
	int err = 0;
#ifndef OLD_POINT
	void *virt;
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,17)
	resource_size_t phys;
#else
	unsigned long phys;
#endif
#else
	u_char *virt;
#endif
	if (!mtd->point || !mtd->unpoint)
		return 0;

#ifndef OLD_POINT
	err = mtd->point(mtd, 0, sbi->mmap_size, &retlen, &virt, &phys);
#else
	err = mtd->point(mtd, 0, sbi->mmap_size, &retlen, &virt);
#endif
	if (err)
		return err;

	if (retlen != sbi->mmap_size) {
#ifndef OLD_POINT
		mtd->unpoint(mtd, 0, retlen);
#else
		mtd->unpoint(mtd, 0, 0, retlen);
#endif
		return -EINVAL;
	}

	sbi->virt_start_addr = (unsigned long)virt;
#ifndef OLD_POINT
	sbi->phys_start_addr = (unsigned long)phys;
#else
	sbi->phys_start_addr = 0;
#endif
	sbi->mtd_pointed = true;

	return 0;
}

void axfs_unmap_mtd(struct super_block *sb)
{
	struct axfs_super *sbi = AXFS_SB(sb);
	struct mtd_info *mtd = (struct mtd_info *)axfs_mtd0(sb);

	if (!sbi)
		return;

	if (axfs_mtd1(sb))
		put_mtd_device((struct mtd_info *)axfs_mtd1(sb));

	if (axfs_is_pointed(sbi)) {
#ifndef OLD_POINT
		mtd->unpoint(mtd, 0, sbi->mmap_size);
#else
		mtd->unpoint(mtd, 0, 0, sbi->mmap_size);
#endif
	} else {
		if (axfs_mtd0(sb))
			put_mtd_device((struct mtd_info *)axfs_mtd0(sb));
	}
}

int axfs_verify_mtd_sizes(struct super_block *sb, int *err)
{
	struct axfs_super *sbi = AXFS_SB(sb);
	struct mtd_info *mtd0 = (struct mtd_info *)axfs_mtd0(sb);
	struct mtd_info *mtd1 = (struct mtd_info *)axfs_mtd1(sb);
	u64 io_dev_size;

	*err = 0;
	io_dev_size = axfs_get_io_dev_size(sb);

	if (!mtd0 && !mtd1)
		return false;

	/* One mtd device entirely mmaped */
	if (sbi->mtd_pointed && !io_dev_size) {
		if (sbi->mmap_size != sbi->size) {
			*err = -EINVAL;
			return false;
		}

		return true;
	}

	if (!io_dev_size)
		return false;

	/* filesystem split across two mtd devs */
	if (mtd1) {
		if (io_dev_size > mtd1->size)
			goto too_small;
		else
			return true;
	}

	/* One mtd device partially mmaped, partially io */
	if (sbi->mtd_pointed) {
		if (sbi->size > mtd0->size)
			goto too_small;
		else
			return true;
	}

	/* One mtd device as a IO dev or split with physaddr */
	if (io_dev_size > mtd0->size)
		goto too_small;

	return true;

too_small:
	printk(KERN_ERR "axfs: filesystem extends beyond end of MTD, ");
	printk(KERN_ERR "expected 0x%llx ", io_dev_size);
	printk(KERN_ERR "got 0x%x\n", (mtd1) ? mtd1->size : mtd0->size);
	*err = -EINVAL;
	return true;
}

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,21)
#else
/* -------------------- START COPY FROM 2.6.22 -------------------------- */
/* MTD-based superblock management
 *
 * Copyright © 2001-2007 Red Hat, Inc. All Rights Reserved.
 * Written by:  David Howells <dhowells@redhat.com>
 *	      David Woodhouse <dwmw2@infradead.org>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version
 * 2 of the License, or (at your option) any later version.
 */

/*
 * compare superblocks to see if they're equivalent
 * - they are if the underlying MTD device is the same
 */
static int get_sb_mtd_compare(struct super_block *sb, void *_mtd)
{
	struct mtd_info *mtd = _mtd;
	struct mtd_info *s_mtd = (struct mtd_info *)axfs_mtd0(sb);

	if (s_mtd == mtd) {
		DEBUG(2, "MTDSB: Match on device %d (\"%s\")\n",
		      mtd->index, mtd->name);
		return 1;
	}

	DEBUG(2, "MTDSB: No match, device %d (\"%s\"), device %d (\"%s\")\n",
	      s_mtd->index, s_mtd->name, mtd->index, mtd->name);
	return 0;
}

/*
 * mark the superblock by the MTD device it is using
 * - set the device number to be the correct MTD block device for pesuperstence
 *   of NFS exports
 */
static int get_sb_mtd_set(struct super_block *sb, void *_mtd)
{
	struct mtd_info *mtd = _mtd;
	struct mtd_info *s_mtd = (struct mtd_info *)axfs_mtd0(sb);

	s_mtd = mtd;
	sb->s_dev = MKDEV(MTD_BLOCK_MAJOR, mtd->index);
	return 0;
}

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,17)
#else
/* Lifted wholesale from 2.6.22 */
int simple_set_mnt(struct vfsmount *mnt, struct super_block *sb)
{
	mnt->mnt_sb = sb;
	mnt->mnt_root = dget(sb->s_root);
	return 0;
}
#endif
/*
 * get a superblock on an MTD-backed filesystem
 */
static int get_sb_mtd_aux(struct file_system_type *fs_type, int flags,
			  const char *dev_name, void *data,
			  struct mtd_info *mtd,
			  int (*fill_super) (struct super_block *, void *, int),
			  struct vfsmount *mnt)
{
	struct axfs_super *sbi = (struct axfs_super *)data;
	struct super_block *sb;
	int ret;

	sb = sget(fs_type, get_sb_mtd_compare, get_sb_mtd_set, mtd);
	if (IS_ERR(sb))
		goto out_error;

	if (sb->s_root)
		goto already_mounted;

	/* fresh new superblock */
	DEBUG(1, "MTDSB: New superblock for device %d (\"%s\")\n",
	      mtd->index, mtd->name);

	sbi->mtd0 = mtd;

	ret = fill_super(sb, data, 0);
	if (ret < 0) {
		up_write(&sb->s_umount);
		deactivate_super(sb);
		return ret;
	}

	/* go */
	sb->s_flags |= MS_ACTIVE;
	return simple_set_mnt(mnt, sb);

	/* new mountpoint for an already mounted superblock */
already_mounted:
	DEBUG(1, "MTDSB: Device %d (\"%s\") is already mounted\n",
	      mtd->index, mtd->name);
	ret = simple_set_mnt(mnt, sb);
	goto out_put;

out_error:
	ret = PTR_ERR(sb);
out_put:
	put_mtd_device(mtd);
	return ret;
}

/*
 * get a superblock on an MTD-backed filesystem by MTD device number
 */
static int get_sb_mtd_nr(struct file_system_type *fs_type, int flags,
			 const char *dev_name, void *data, int mtdnr,
			 int (*fill_super) (struct super_block *, void *, int),
			 struct vfsmount *mnt)
{
	struct mtd_info *mtd;

	mtd = get_mtd_device(NULL, mtdnr);
	if (IS_ERR(mtd)) {
		DEBUG(0, "MTDSB: Device #%u doesn't appear to exist\n", mtdnr);
		return PTR_ERR(mtd);
	}

	return get_sb_mtd_aux(fs_type, flags, dev_name, data, mtd, fill_super,
			      mnt);
}

/*
 * set up an MTD-based superblock
 */
static int get_sb_mtd(struct file_system_type *fs_type, int flags,
		      const char *dev_name, void *data,
		      int (*fill_super) (struct super_block *, void *, int),
		      struct vfsmount *mnt)
{
	struct nameidata nd;
	int mtdnr, ret;

	if (!dev_name)
		return -EINVAL;

	DEBUG(2, "MTDSB: dev_name \"%s\"\n", dev_name);

	/* the preferred way of mounting in future; especially when
	 * CONFIG_BLOCK=n - we specify the underlying MTD device by number or
	 * by name, so that we don't require block device support to be present
	 * in the kernel. */
	if (dev_name[0] == 'm' && dev_name[1] == 't' && dev_name[2] == 'd') {
		if (dev_name[3] == ':') {
			struct mtd_info *mtd;

			/* mount by MTD device name */
			DEBUG(1, "MTDSB: mtd:%%s, name \"%s\"\n", dev_name + 4);

			for (mtdnr = 0; mtdnr < MAX_MTD_DEVICES; mtdnr++) {
				mtd = get_mtd_device(NULL, mtdnr);
				if (!IS_ERR(mtd)) {
					if (!strcmp(mtd->name, dev_name + 4))
						return get_sb_mtd_aux(fs_type,
								      flags,
								      dev_name,
								      data, mtd,
								      fill_super,
								      mnt);

					put_mtd_device(mtd);
				}
			}

			printk(KERN_NOTICE "MTD:"
			       " MTD device with name \"%s\" not found.\n",
			       dev_name + 4);

		} else if (isdigit(dev_name[3])) {
			/* mount by MTD device number name */
			char *endptr;

			mtdnr = simple_strtoul(dev_name + 3, &endptr, 0);
			if (!*endptr) {
				/* It was a valid number */
				DEBUG(1, "MTDSB: mtd%%d, mtdnr %d\n", mtdnr);
				return get_sb_mtd_nr(fs_type, flags,
						     dev_name, data,
						     mtdnr, fill_super, mnt);
			}
		}
	}

	/* try the old way - the hack where we allowed users to mount
	 * /dev/mtdblock$(n) but didn't actually _use_ the blockdev
	 */
	ret = path_lookup(dev_name, LOOKUP_FOLLOW, &nd);

	DEBUG(1, "MTDSB: path_lookup() returned %d, inode %p\n",
	      ret, nd.dentry ? nd.dentry->d_inode : NULL);

	if (ret)
		return ret;

	ret = -EINVAL;

	if (!S_ISBLK(nd.dentry->d_inode->i_mode))
		goto out;

	if (nd.mnt->mnt_flags & MNT_NODEV) {
		ret = -EACCES;
		goto out;
	}

	if (imajor(nd.dentry->d_inode) != MTD_BLOCK_MAJOR)
		goto not_an_MTD_device;

	mtdnr = iminor(nd.dentry->d_inode);
	path_release(&nd);

	return get_sb_mtd_nr(fs_type, flags, dev_name, data, mtdnr, fill_super,
			     mnt);

not_an_MTD_device:
	printk(KERN_NOTICE
	       "MTD: Attempt to mount non-MTD device \"%s\"\n", dev_name);
out:
	path_release(&nd);
	return ret;

}

/*
 * destroy an MTD-based superblock
 */
static void kill_mtd_super(struct super_block *sb)
{
	struct mtd_info *s_mtd = (struct mtd_info *)axfs_mtd0(sb);
	struct axfs_super *sbi = AXFS_SB(sb);
	generic_shutdown_super(sb);
	put_mtd_device(s_mtd);
	sbi->mtd0 = NULL;
}

/* ---------------------- END COPY --------------------------------------*/
#endif

int axfs_get_sb_mtd(struct file_system_type *fs_type, int flags,
		    const char *dev_name, struct axfs_super *sbi,
		    struct vfsmount *mnt, int *err)
{
	int nflags, mtdnr;

	if (axfs_is_dev_mtd(sbi->second_dev, &mtdnr)) {
		sbi->mtd1 = (void *)axfs_get_mtd_device(mtdnr);
		if (!sbi->mtd1) {
			*err = -EINVAL;
			return false;
		}
	}
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,17)
	nflags = flags & MS_SILENT;
#else
	nflags = flags;
#endif

	*err = get_sb_mtd(fs_type, nflags, dev_name, sbi, axfs_fill_super, mnt);
	if (*err)
		return false;

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,21)
	sbi->mtd0 = mnt->mnt_sb->s_mtd;
#endif
	return true;
}

void axfs_kill_mtd_super(struct super_block *sb)
{
	kill_mtd_super(sb);
}
#else
struct mtd_info *axfs_mtd(struct super_block *sb)
{
	return NULL;
}

struct mtd_info *axfs_mtd0(struct super_block *sb)
{
	return NULL;
}

struct mtd_info *axfs_mtd1(struct super_block *sb)
{
	return NULL;
}

int axfs_has_mtd(struct super_block *sb)
{
	return false;
}

struct mtd_info *axfs_get_mtd_device(int mtdnr)
{
	return NULL;
}

int axfs_map_mtd(struct super_block *sb)
{
	return 0;
}

void axfs_unmap_mtd(struct super_block *sb)
{
}

int axfs_copy_mtd(struct super_block *sb, void *dst, u64 fsoffset, u64 len)
{
	return -EINVAL;
}

int axfs_get_sb_mtd(struct file_system_type *fs_type, int flags,
		    const char *dev_name, struct axfs_super *sbi,
		    struct vfsmount *mnt, int *err)
{
	return false;
}

int axfs_is_dev_mtd(char *path, int *mtdnr)
{
	return false;
}

void axfs_kill_mtd_super(struct super_block *sb)
{
}

int axfs_verify_mtd_sizes(struct super_block *sb, int *err)
{
	*err = 0;
	return true;
}

#endif /* CONFIG_MTD */

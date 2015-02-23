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
 * More info and current contacts at http://axfs.sourceforge.net
 *
 * axfs_super.c -
 *   Contains the core code used to mount the fs.
 *
 */
#include "axfs.h"

#include <linux/vmalloc.h>
#include <linux/slab.h>
#include <linux/parser.h>
#include <linux/statfs.h>
#include <linux/module.h>
#include <linux/mount.h>
#include <linux/mtd/mtd.h>

static struct super_operations axfs_sops;

static int axfs_is_region_compressed(struct axfs_region_desc *region)
{
	if (region->compressed_size > 0)
		return true;

	return false;
}

static int axfs_is_mmapable(struct axfs_super *sbi, u64 offset)
{
	if (sbi->mmap_size > offset)
		return true;

	return false;
}

static int axfs_is_region_mmapable(struct axfs_super *sbi,
				   struct axfs_region_desc *region)
{
	if (axfs_is_mmapable(sbi, region->fsoffset))
		if (axfs_virtaddr_is_valid(sbi))
			return true;

	return false;
}

static int axfs_is_offset_mmapable(struct axfs_super *sbi, u64 offset)
{
	if (axfs_is_mmapable(sbi, offset))
		if (axfs_virtaddr_is_valid(sbi))
			return true;

	return false;
}

static int axfs_is_region_incore(struct axfs_region_desc *region)
{
	if (region->incore > 0)
		return true;

	return false;
}

static int axfs_is_region_xip(struct axfs_super *sbi,
			      struct axfs_region_desc *region)
{
	if (!axfs_can_xip(sbi))
		return false;

	if (!axfs_is_region_mmapable(sbi, region))
		return false;

	if (axfs_is_region_compressed(region))
		return false;

	if (axfs_is_region_incore(region))
		return false;

	return true;
}

int axfs_physaddr_is_valid(struct axfs_super *sbi)
{
	if (sbi->phys_start_addr > 0)
		return true;

	return false;
}

int axfs_virtaddr_is_valid(struct axfs_super *sbi)
{
	if (sbi->virt_start_addr > 0)
		return true;

	return false;
}

int axfs_is_iomem(struct axfs_super *sbi)
{
	if (sbi->iomem_size > 0)
		return true;

	return false;
}

int axfs_is_pointed(struct axfs_super *sbi)
{
	if (sbi->mtd_pointed > 0)
		return true;

	return false;
}

int axfs_can_xip(struct axfs_super *sbi)
{
	if (axfs_is_pointed(sbi)) {
		if (!axfs_physaddr_is_valid(sbi))
			return false;
	}

	if (!axfs_virtaddr_is_valid(sbi))
		return false;

	return true;
}

int axfs_is_physmem(struct axfs_super *sbi)
{
	int phys = axfs_physaddr_is_valid(sbi);
	int iomem = axfs_is_iomem(sbi);
	int point = axfs_is_pointed(sbi);

	if (phys && !iomem && !point)
		return true;

	return false;
}

u64 axfs_fsoffset_to_devoffset(struct axfs_super *sbi, u64 fsoffset)
{
	if (sbi->phys_start_addr == 0)
		return fsoffset;

	if (sbi->mtd1 == NULL || sbi->second_dev == NULL)
		return fsoffset;

	if (fsoffset >= sbi->mmap_size)
		return fsoffset - sbi->mmap_size;

	return fsoffset;
}

int axfs_nodev(struct super_block *sb)
{
	if (!axfs_has_mtd(sb) && !axfs_has_bdev(sb))
		return true;

	return false;
}

static void axfs_free_region(struct axfs_super *sbi,
			     struct axfs_region_desc *region)
{
	if (!region)
		return;

	if (axfs_is_region_xip(sbi, region))
		return;

	vfree(region->virt_addr);
}

static struct axfs_super *axfs_get_sbi(void)
{
	struct axfs_super *sbi;

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,13)
	sbi = kzalloc(sizeof(*sbi), GFP_KERNEL);
#else
	sbi = kmalloc(sizeof(*sbi), GFP_KERNEL);
	memset(sbi, 0, sizeof(*sbi));
#endif
	if (sbi)
		return sbi;

	return ERR_PTR(-ENOMEM);
}

static void axfs_put_sbi(struct axfs_super *sbi)
{
	if (!sbi)
		return;

	axfs_shutdown_profiling(sbi);

	axfs_free_region(sbi, &sbi->strings);
	axfs_free_region(sbi, &sbi->xip);
	axfs_free_region(sbi, &sbi->compressed);
	axfs_free_region(sbi, &sbi->byte_aligned);
	axfs_free_region(sbi, &sbi->node_type);
	axfs_free_region(sbi, &sbi->node_index);
	axfs_free_region(sbi, &sbi->cnode_offset);
	axfs_free_region(sbi, &sbi->cnode_index);
	axfs_free_region(sbi, &sbi->banode_offset);
	axfs_free_region(sbi, &sbi->cblock_offset);
	axfs_free_region(sbi, &sbi->inode_file_size);
	axfs_free_region(sbi, &sbi->inode_name_offset);
	axfs_free_region(sbi, &sbi->inode_num_entries);
	axfs_free_region(sbi, &sbi->inode_mode_index);
	axfs_free_region(sbi, &sbi->inode_array_index);
	axfs_free_region(sbi, &sbi->modes);
	axfs_free_region(sbi, &sbi->uids);
	axfs_free_region(sbi, &sbi->gids);

	kfree(sbi->second_dev);
	vfree(sbi->cblock_buffer[0]);
	vfree(sbi->cblock_buffer[1]);
	kfree(sbi);
}

static void axfs_put_super(struct super_block *sb)
{
#ifndef NO_PHYSMEM
	/* Grab our remapped address before we blow away sbi */
	void *addr = axfs_get_physmem_addr(sb);
#endif
	axfs_unmap_mtd(sb);
	axfs_put_sbi(AXFS_SB(sb));
	sb->s_fs_info = NULL;
#ifndef NO_PHYSMEM
	axfs_unmap_physmem(addr);
#endif
}

static void axfs_copy_mem(struct super_block *sb, void *buf, u64 fsoffset,
			  u64 len)
{
	struct axfs_super *sbi = AXFS_SB(sb);
	unsigned long addr;

	addr = sbi->virt_start_addr + (unsigned long)fsoffset;

	memcpy(buf, (void *)addr, (size_t) len);
}

static int axfs_copy_metadata(struct super_block *sb, void *buf, u64 fsoffset,
			      u64 len)
{
	struct axfs_super *sbi = AXFS_SB(sb);
	u64 end = fsoffset + len;
	u64 a = sbi->mmap_size - fsoffset;
	u64 b = end - sbi->mmap_size;
	void *bb = (void *)((unsigned long)buf + (unsigned long)a);
	int err = 0;

	/* Catches case where sbi is not yet fully initialized. */
	if ((sbi->magic == 0) && (sbi->virt_start_addr != 0)) {
		axfs_copy_mem(sb, buf, fsoffset, len);
		return 0;
	}

	if (fsoffset < sbi->mmap_size) {
		if (end > sbi->mmap_size) {
			err = axfs_copy_metadata(sb, buf, fsoffset, a);
			if (err)
				return err;
			err = axfs_copy_metadata(sb, bb, sbi->mmap_size, b);
		} else {
			if (axfs_is_offset_mmapable(sbi, fsoffset))
				axfs_copy_mem(sb, buf, fsoffset, len);
			else if (axfs_has_bdev(sb))
				axfs_copy_block(sb, buf, fsoffset, len);
			else if (axfs_has_mtd(sb))
				err = axfs_copy_mtd(sb, buf, fsoffset, len);
		}
	} else {
		if (axfs_nodev(sb))
			axfs_copy_mem(sb, buf, fsoffset, len);
		else if (axfs_has_bdev(sb))
			axfs_copy_block(sb, buf, fsoffset, len);
		else if (axfs_has_mtd(sb))
			err = axfs_copy_mtd(sb, buf, fsoffset, len);
	}
	return err;
}

static int axfs_fill_region_data(struct super_block *sb,
				 struct axfs_region_desc *region, int force)
{
	struct axfs_super *sbi = AXFS_SB(sb);
	unsigned long addr;
	void *buff = NULL;
	void *vaddr;
	int err = -ENOMEM;
	u64 size = region->size;
	u64 fsoffset = region->fsoffset;
	u64 end = fsoffset + size;
	u64 c_size = region->compressed_size;

	if (size == 0)
		return 0;

	if (axfs_is_region_incore(region))
		goto incore;

	if (axfs_is_region_compressed(region))
		goto incore;

	if (axfs_is_region_xip(sbi, region)) {
		if ((end > sbi->mmap_size) && (force))
			goto incore;
		addr = sbi->virt_start_addr;
		addr += (unsigned long)fsoffset;
		region->virt_addr = (void *)addr;
		return 0;
	}

	if (force)
		goto incore;

	region->virt_addr = NULL;
	return 0;

incore:
	region->virt_addr = vmalloc(size);
	if (!region->virt_addr)
		goto out;
	vaddr = region->virt_addr;

	if (axfs_is_region_compressed(region)) {
		buff = vmalloc(c_size);
		if (!buff)
			goto out;
		axfs_copy_metadata(sb, buff, fsoffset, c_size);
		err = axfs_uncompress_block(vaddr, size, buff, c_size);
		if (!err)
			goto out;
		vfree(buff);
	} else {
		axfs_copy_metadata(sb, vaddr, fsoffset, size);
	}

	return 0;

out:
	vfree(buff);
	vfree(region->virt_addr);
	return err;
}

static int axfs_fill_region_data_ptrs(struct super_block *sb)
{
	int err;
	struct axfs_super *sbi = AXFS_SB(sb);

	err = axfs_fill_region_data(sb, &sbi->strings, true);
	if (err)
		goto out;
	err = axfs_fill_region_data(sb, &sbi->xip, true);
	if (err)
		goto out;
	err = axfs_fill_region_data(sb, &sbi->compressed, false);
	if (err)
		goto out;
	err = axfs_fill_region_data(sb, &sbi->byte_aligned, false);
	if (err)
		goto out;
	err = axfs_fill_region_data(sb, &sbi->node_type, true);
	if (err)
		goto out;
	err = axfs_fill_region_data(sb, &sbi->node_index, true);
	if (err)
		goto out;
	err = axfs_fill_region_data(sb, &sbi->cnode_offset, true);
	if (err)
		goto out;
	err = axfs_fill_region_data(sb, &sbi->cnode_index, true);
	if (err)
		goto out;
	err = axfs_fill_region_data(sb, &sbi->banode_offset, true);
	if (err)
		goto out;
	err = axfs_fill_region_data(sb, &sbi->cblock_offset, true);
	if (err)
		goto out;
	err = axfs_fill_region_data(sb, &sbi->inode_file_size, true);
	if (err)
		goto out;
	err = axfs_fill_region_data(sb, &sbi->inode_name_offset, true);
	if (err)
		goto out;
	err = axfs_fill_region_data(sb, &sbi->inode_num_entries, true);
	if (err)
		goto out;
	err = axfs_fill_region_data(sb, &sbi->inode_mode_index, true);
	if (err)
		goto out;
	err = axfs_fill_region_data(sb, &sbi->inode_array_index, true);
	if (err)
		goto out;
	err = axfs_fill_region_data(sb, &sbi->modes, true);
	if (err)
		goto out;
	err = axfs_fill_region_data(sb, &sbi->uids, true);
	if (err)
		goto out;
	err = axfs_fill_region_data(sb, &sbi->gids, true);
	if (err)
		goto out;

out:
	return err;
}

static int axfs_init_cblock_buffers(struct axfs_super *sbi)
{
	sbi->current_cnode_index = -1;
	sbi->cblock_buffer[0] = vmalloc(sbi->cblock_size);
	sbi->cblock_buffer[1] = vmalloc(sbi->cblock_size);
	if ((!sbi->cblock_buffer[0]) || (!sbi->cblock_buffer[1]))
		return -ENOMEM;

	return 0;
}

static int axfs_fixup_devices(struct super_block *sb)
{
	struct axfs_super *sbi = AXFS_SB(sb);
	int err = 0;

#ifndef NO_PHYSMEM
	if (axfs_is_physmem(sbi)) {
		axfs_map_physmem(sbi, sbi->mmap_size);
	} else if (axfs_has_mtd(sb)) {
#else
	if (axfs_has_mtd(sb)) {
#endif
		err = axfs_map_mtd(sb);
	} else if (axfs_is_iomem(sbi)) {
		sbi->phys_start_addr = 0;
	}

	if (!(axfs_virtaddr_is_valid(sbi)))
		sbi->mmap_size = 0;

	return err;
}

static void axfs_fill_region_desc(struct super_block *sb,
				  struct axfs_region_desc_onmedia *out,
				  __be64 offset_be, struct axfs_region_desc *in)
{
	u64 offset = be64_to_cpu(offset_be);

	axfs_copy_metadata(sb, (void *)out, offset, sizeof(*out));

	in->fsoffset = be64_to_cpu(out->fsoffset);
	in->size = be64_to_cpu(out->size);
	in->compressed_size = be64_to_cpu(out->compressed_size);
	in->max_index = be64_to_cpu(out->max_index);
	in->table_byte_depth = out->table_byte_depth;
	in->incore = out->incore;
}

static int axfs_fill_region_descriptors(struct super_block *sb,
					struct axfs_super_onmedia *sbo)
{
	struct axfs_super *sbi = AXFS_SB(sb);
	struct axfs_region_desc_onmedia *out;

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,13)
	out = kzalloc(sizeof(*out), GFP_KERNEL);
#else
	out = kmalloc(sizeof(*out), GFP_KERNEL);
#endif
	if (!out)
		return -ENOMEM;
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,13)
#else
	memset(out, 0, sizeof(*out));
#endif

	axfs_fill_region_desc(sb, out, sbo->strings, &sbi->strings);
	axfs_fill_region_desc(sb, out, sbo->xip, &sbi->xip);
	axfs_fill_region_desc(sb, out, sbo->compressed, &sbi->compressed);
	axfs_fill_region_desc(sb, out, sbo->byte_aligned, &sbi->byte_aligned);
	axfs_fill_region_desc(sb, out, sbo->node_type, &sbi->node_type);
	axfs_fill_region_desc(sb, out, sbo->node_index, &sbi->node_index);
	axfs_fill_region_desc(sb, out, sbo->cnode_offset, &sbi->cnode_offset);
	axfs_fill_region_desc(sb, out, sbo->cnode_index, &sbi->cnode_index);
	axfs_fill_region_desc(sb, out, sbo->banode_offset, &sbi->banode_offset);
	axfs_fill_region_desc(sb, out, sbo->cblock_offset, &sbi->cblock_offset);
	axfs_fill_region_desc(sb, out, sbo->inode_file_size,
			      &sbi->inode_file_size);
	axfs_fill_region_desc(sb, out, sbo->inode_name_offset,
			      &sbi->inode_name_offset);
	axfs_fill_region_desc(sb, out, sbo->inode_num_entries,
			      &sbi->inode_num_entries);
	axfs_fill_region_desc(sb, out, sbo->inode_mode_index,
			      &sbi->inode_mode_index);
	axfs_fill_region_desc(sb, out, sbo->inode_array_index,
			      &sbi->inode_array_index);
	axfs_fill_region_desc(sb, out, sbo->modes, &sbi->modes);
	axfs_fill_region_desc(sb, out, sbo->uids, &sbi->uids);
	axfs_fill_region_desc(sb, out, sbo->gids, &sbi->gids);

	kfree(out);

	return 0;
}

static int axfs_check_page_shift(struct axfs_super *sbi)
{
	if (sbi->page_shift != PAGE_SHIFT) {
		printk(KERN_ERR "axfs: Filesystem is AXFS, however "
				"the page size does not match that\n"
				"of the system. Cowardly refusing "
				"to mount.\n");
		return -EINVAL;
	}

	return 0;
}

static int axfs_check_compression_type(struct axfs_super *sbi)
{
	if (sbi->compression_type != ZLIB) {
		printk(KERN_ERR "axfs: Unknown compression type "
				"specified in super block.\n");
		return -EINVAL;
	}

	return 0;
}

static int axfs_get_onmedia_super(struct super_block *sb)
{
	int err;
	struct axfs_super *sbi = AXFS_SB(sb);
	struct axfs_super_onmedia *sbo;

	sbo = kmalloc(sizeof(*sbo), GFP_KERNEL);
	if (!sbo)
		return -ENOMEM;

#ifndef NO_PHYSMEM
	axfs_map_physmem(sbi, sizeof(*sbo));
#endif
	axfs_copy_metadata(sb, (void *)sbo, 0, sizeof(*sbo));

	/* Do sanity checks on the superblock */
	if (be32_to_cpu(sbo->magic) != AXFS_MAGIC) {
		printk(KERN_ERR "axfs: wrong magic: got %x, expected %x\n",
		       be32_to_cpu(sbo->magic), AXFS_MAGIC);
		err = -EINVAL;
		goto out;
	}

	/* verify the signiture is correct */
	if (strncmp(sbo->signature, AXFS_SIGNATURE, sizeof(AXFS_SIGNATURE))) {
		printk(KERN_ERR "axfs: wrong signature: "
				"got '%s', expected '%s'\n",
		       sbo->signature, AXFS_SIGNATURE);
		err = -EINVAL;
		goto out;
	}

	sbi->magic = be32_to_cpu(sbo->magic);
	sbi->version_major = sbo->version_major;
	sbi->version_minor = sbo->version_minor;
	sbi->version_sub = sbo->version_sub;
	sbi->files = be64_to_cpu(sbo->files);
	sbi->size = be64_to_cpu(sbo->size);
	sbi->blocks = be64_to_cpu(sbo->blocks);
	sbi->mmap_size = be64_to_cpu(sbo->mmap_size);
	sbi->cblock_size = be32_to_cpu(sbo->cblock_size);
	sbi->timestamp.tv_sec = be64_to_cpu(sbo->timestamp);
	sbi->timestamp.tv_nsec = 0;
	sbi->compression_type = sbo->compression_type;
	sbi->page_shift = sbo->page_shift;

	err = axfs_check_page_shift(sbi);
	if (err)
		goto out;

	err = axfs_check_compression_type(sbi);
	if (err)
		goto out;

	/* If no block or MTD device, adjust mmapable to cover all image */
	if (axfs_nodev(sb))
		sbi->mmap_size = sbi->size;

	err = axfs_fill_region_descriptors(sb, sbo);

out:
	kfree(sbo);
#ifndef NO_PHYSMEM
	axfs_unmap_physmem(axfs_get_physmem_addr(sb));
#endif
	return err;
}

u64 axfs_get_io_dev_size(struct super_block *sb)
{
	struct axfs_super *sbi = AXFS_SB(sb);
	return sbi->size - sbi->mmap_size;
}

/* Verify that the size of the IO segment of a split filesystem
   is less than or equal to that of the device containing it.
*/
static int axfs_verify_device_sizes(struct super_block *sb)
{
	int err;

	if (axfs_verify_bdev_sizes(sb, &err))
		goto out;

	if (axfs_verify_mtd_sizes(sb, &err))
		goto out;

out:
	return err;
}

/* Read the last four bytes of the volume and make sure the AXFS magic is
   present. */
static int axfs_verify_eofs_magic(struct super_block *sb)
{
	struct axfs_super *sbi = AXFS_SB(sb);
	u32 eof_magic;
	u64 fsoffset = sbi->size - sizeof(eof_magic);

	if (axfs_copy_metadata(sb, &eof_magic, fsoffset, sizeof(eof_magic)))
		return -EINVAL;

	if (be32_to_cpu(eof_magic) == AXFS_MAGIC)
		return 0;

	printk(KERN_ERR "axfs: bad magic at end of image: got %x expected %x\n",
	       be32_to_cpu(eof_magic), AXFS_MAGIC);
	return -EINVAL;
}

static int axfs_do_fill_super(struct super_block *sb)
{
	struct axfs_super *sbi = AXFS_SB(sb);
	int err;

	err = axfs_get_onmedia_super(sb);
	if (err)
		goto out;

	err = axfs_fixup_devices(sb);
	if (err)
		goto out;

	err = axfs_verify_device_sizes(sb);
	if (err)
		goto out;

	err = axfs_verify_eofs_magic(sb);
	if (err)
		goto out;

	err = axfs_fill_region_data_ptrs(sb);
	if (err)
		goto out;

	/* Check that the root inode is in a sane state */
	if (!S_ISDIR(axfs_get_mode(sbi, 0))) {
		printk(KERN_ERR "axfs: root is not a directory\n");
		err = -EINVAL;
		goto out;
	}

	if (axfs_get_inode_num_entries(sbi, 0) == 0) {
		printk(KERN_INFO "axfs: empty filesystem\n");
		err = -EINVAL;
		goto out;
	}

	err = axfs_init_cblock_buffers(sbi);
	if (err)
		goto out;

	init_rwsem(&sbi->lock);

	return 0;

out:
	axfs_put_super(sb);
	return err;
}

int axfs_fill_super(struct super_block *sb, void *data, int silent)
{
	struct axfs_super *sbi;
	struct inode *root;
	int err;
	struct axfs_super *sbi_in = (struct axfs_super *)data;

	sbi = axfs_get_sbi();
	if (IS_ERR(sbi))
		return PTR_ERR(sbi);

	sb->s_fs_info = (void *)sbi;

	memcpy(sbi, sbi_in, sizeof(*sbi));

	/* fully populate the incore superblock structures */
	err = axfs_do_fill_super(sb);
	if (err)
		goto out;

	sb->s_flags |= MS_RDONLY;

	/* Setup the VFS super block now */
	sb->s_op = &axfs_sops;
	root = axfs_create_vfs_inode(sb, 0);
	if (!root) {
		err = -EINVAL;
		goto out;
	}

#if LINUX_VERSION_CODE > KERNEL_VERSION(3,3,0)
	sb->s_root = d_make_root(root);
#else
	sb->s_root = d_alloc_root(root);
#endif
	if (!sb->s_root) {
#if LINUX_VERSION_CODE > KERNEL_VERSION(3,3,0)
#else
		iput(root);
#endif
		err = -EINVAL;
		goto out;
	}

	err = axfs_init_profiling(sbi);
	if (err)
		goto out;

	return 0;

out:
	axfs_put_super(sb);
	return err;
}

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,36)
static struct dentry  *
axfs_mount_address(struct file_system_type *fs_type,
					int flags, struct axfs_super *sbi)
#else
static int axfs_get_sb_address(struct file_system_type *fs_type, int flags,
			       struct axfs_super *sbi, struct vfsmount *mnt,
			       int *err)
#endif
{
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,36)
	struct dentry *dp = NULL;
#else
	int mtdnr;
#endif
	char *sd = sbi->second_dev;

	if (sbi->phys_start_addr == 0)
		return false;

	if (sbi->phys_start_addr & (PAGE_SIZE - 1)) {
		printk(KERN_ERR
		       "axfs: address 0x%lx for axfs image isn't aligned "
		       "to a page boundary\n", sbi->phys_start_addr);
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,36)
		return ERR_PTR(-EINVAL);
	}

	dp = axfs_mount_mtd(fs_type, flags, sd, sbi);
	if (!IS_ERR_OR_NULL(dp))
		return dp;

	dp = axfs_mount_bdev(fs_type, flags, sd, sbi);
	if (!IS_ERR_OR_NULL(dp))
		return dp;

	return mount_nodev(fs_type, flags, sbi, axfs_fill_super);
#else
		*err = -EINVAL;
		return true;
	}
	if (axfs_is_dev_mtd(sd, &mtdnr)) {
		return axfs_get_sb_mtd(fs_type, flags, sd, sbi, mnt, err);
	} else if (axfs_is_dev_bdev(sd)) {
		return axfs_get_sb_bdev(fs_type, flags, sd, sbi, mnt, err);
	} else {
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,17)
		*err = get_sb_nodev(fs_type, flags, sbi, axfs_fill_super, mnt);
#else
		mnt->mnt_sb =
		    get_sb_nodev(fs_type, flags, (void *)sbi, axfs_fill_super);
#endif
	}

	return true;
#endif
}

/* helpers for parse_axfs_options */
enum {
	OPTION_ERR,
	OPTION_SECOND_DEV,
	OPTION_PHYSICAL_ADDRESS_LOWER_X,
	OPTION_PHYSICAL_ADDRESS_UPPER_X,
	OPTION_IOMEM
};

/* helpers for parse_axfs_options */
static match_table_t tokens = {
	{OPTION_SECOND_DEV, "second_dev=%s"},
	{OPTION_PHYSICAL_ADDRESS_LOWER_X, "physaddr=0x%s"},
	{OPTION_PHYSICAL_ADDRESS_UPPER_X, "physaddr=0X%s"},
	{OPTION_IOMEM, "iomem=%s"},
	{OPTION_ERR, NULL}
};

static int axfs_check_options(char *options, struct axfs_super *sbi)
{
	int err = -EINVAL;
	unsigned long address = 0;
	char *iomem = NULL;
	unsigned long length = 0;
	char *p;
	substring_t args[MAX_OPT_ARGS];

	if (!options)
		return 0;

	if (!*options)
		return 0;

	while ((p = strsep(&options, ",")) != NULL) {
		int token;
		if (!*p)
			continue;

		token = match_token(p, tokens, args);
		switch (token) {
		case OPTION_SECOND_DEV:
			sbi->second_dev = match_strdup(&args[0]);
			if (!(sbi->second_dev)) {
				err = -ENOMEM;
				goto out;
			}
			if (!*(sbi->second_dev))
				goto bad_value;
			break;
		case OPTION_IOMEM:
			iomem = match_strdup(&args[0]);
			if (!(iomem)) {
				err = -ENOMEM;
				goto out;
			}
			if (!*iomem)
				goto bad_value;
			break;
		case OPTION_PHYSICAL_ADDRESS_LOWER_X:
		case OPTION_PHYSICAL_ADDRESS_UPPER_X:
			if (match_hex(&args[0], (int *)&address))
				goto out;
			if (!address)
				goto bad_value;
			break;
		default:
			printk(KERN_ERR
			       "axfs: unrecognized mount option '%s' "
			       "or missing value\n", p);
			goto out;
		}
	}

	if (iomem) {
		if (address)
			goto out;
		err = axfs_get_uml_address(iomem, &address, &length);
		kfree(iomem);
		sbi->iomem_size = length;
		sbi->virt_start_addr = address;
	}

	sbi->phys_start_addr = address;
	return 0;

bad_value:
	printk(KERN_ERR
	       "axfs: unrecognized mount option '%s' "
	       "or missing value\n", p);

out:
	kfree(iomem);
	return err;
}

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,36)
struct dentry *axfs_mount(struct file_system_type *fs_type, int flags,
		const char *dev_name, void *data)
{
	struct axfs_super *sbi;
	int err;
	struct dentry *ret = ERR_PTR(-EINVAL);

	sbi = axfs_get_sbi();
	if (IS_ERR(sbi))
		return ERR_CAST(sbi);

	err = axfs_check_options((char *)data, sbi);
	if (err) {
		ret = ERR_PTR(err);
		goto out;
	}

	/* First we check if we are mounting directly to memory */
	ret = axfs_mount_address(fs_type, flags, sbi);
	if (!(IS_ERR_OR_NULL(ret)))
		goto out;

	/* Next we assume there's a MTD device */
	ret = axfs_mount_mtd(fs_type, flags, dev_name, sbi);
	if (!(IS_ERR_OR_NULL(ret)))
		goto out;

	/* Now we assume it's a block device */
	if (sbi->second_dev) {
		printk(KERN_ERR
		       "axfs: can't specify secondary block device %s because "
		       "%s is assumed to be a block device\n", sbi->second_dev,
		       dev_name);
		ret = ERR_PTR(-EINVAL);
		goto out;
	}
	ret = axfs_mount_bdev(fs_type, flags, dev_name, sbi);
	if (!(IS_ERR_OR_NULL(ret)))
		goto out;
	ret = ERR_PTR(-EINVAL);

out:
	axfs_put_sbi(sbi);
	return ret;
}
#else
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,17)
int axfs_get_sb(struct file_system_type *fs_type, int flags,
		const char *dev_name, void *data, struct vfsmount *mnt)
#else
struct super_block *axfs_get_sb(struct file_system_type *fs_type, int flags,
				const char *dev_name, void *data)
#endif
{
	struct axfs_super *sbi;
	int err;
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,17)
#else
	struct super_block *sb;
	struct vfsmount *mnt;
	mnt = kmalloc(sizeof(*mnt), GFP_KERNEL);
	memset(mnt, 0, sizeof(*mnt));
#endif

	sbi = axfs_get_sbi();
	if (IS_ERR(sbi))
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,17)
		return PTR_ERR(sbi);
#else
		return (struct super_block *)sbi;
#endif

	err = axfs_check_options((char *)data, sbi);
	if (err)
		goto out;

	/* First we check if we are mounting directly to memory */
	if (axfs_get_sb_address(fs_type, flags, sbi, mnt, &err))
		goto out;

	/* Next we assume there's a MTD device */
	if (axfs_get_sb_mtd(fs_type, flags, dev_name, sbi, mnt, &err))
		goto out;

	/* Now we assume it's a block device */
	if (sbi->second_dev) {
		printk(KERN_ERR
		       "axfs: can't specify secondary block device %s because "
		       "%s is assumed to be a block device\n", sbi->second_dev,
		       dev_name);
		err = -EINVAL;
		goto out;
	}

	if (axfs_get_sb_bdev(fs_type, flags, dev_name, sbi, mnt, &err))
		goto out;

	err = -EINVAL;

out:
	axfs_put_sbi(sbi);
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,17)
	return err;
#else
	if (err)
		return ERR_PTR(err);

	sb = mnt->mnt_sb;
	kfree(mnt);
	return sb;
#endif
}
#endif

static void axfs_kill_super(struct super_block *sb)
{
	if (axfs_nodev(sb))
		return kill_anon_super(sb);

	if (axfs_has_mtd(sb))
		axfs_kill_mtd_super(sb);

	if (axfs_has_bdev(sb))
		axfs_kill_block_super(sb);
}

static int axfs_remount(struct super_block *sb, int *flags, char *data)
{
	*flags |= MS_RDONLY;
	return 0;
}

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,17)
static int axfs_statfs(struct dentry *dentry, struct kstatfs *buf)
{
	struct axfs_super *sbi = AXFS_SB(dentry->d_sb);
#else
static int axfs_statfs(struct super_block *sb, struct kstatfs *buf)
{
	struct axfs_super *sbi = AXFS_SB(sb);
#endif

	buf->f_type = AXFS_MAGIC;
	buf->f_bsize = (1 << sbi->page_shift);
	buf->f_blocks = sbi->blocks;
	buf->f_bfree = 0;
	buf->f_bavail = 0;
	buf->f_files = sbi->files;
	buf->f_ffree = 0;
	buf->f_namelen = AXFS_MAXPATHLEN;
	return 0;
}

static struct super_operations axfs_sops = {
	.put_super = axfs_put_super,
	.remount_fs = axfs_remount,
	.statfs = axfs_statfs,
};

static struct file_system_type axfs_fs_type = {
	.owner = THIS_MODULE,
	.name = "axfs",
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,36)
	.mount = axfs_mount,
#else
	.get_sb = axfs_get_sb,
#endif
	.kill_sb = axfs_kill_super,
};

static int __init init_axfs_fs(void)
{
	int err;

	err = axfs_uncompress_init();
	if (err)
		return err;

	err = register_filesystem(&axfs_fs_type);

	if (!err)
		return 0;

	axfs_uncompress_exit();
	return err;
}

static void __exit exit_axfs_fs(void)
{
	axfs_uncompress_exit();
	unregister_filesystem(&axfs_fs_type);
}

module_init(init_axfs_fs);
module_exit(exit_axfs_fs);
MODULE_LICENSE("GPL");

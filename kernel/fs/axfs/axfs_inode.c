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
 *
 * Borrowed heavily from fs/cramfs/inode.c by Linus Torvalds
 *
 * axfs_inode.c -
 *   Contains the most of the filesystem logic with the major exception of the
 *   mounting infrastructure.
 *
 */
#include "axfs.h"

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,5,0)
#else
#include <asm/uaccess.h>
#endif

static const struct file_operations axfs_directory_operations;
static const struct file_operations axfs_fops;
static struct address_space_operations axfs_aops;
static struct inode_operations axfs_dir_inode_operations;
static struct vm_operations_struct axfs_vm_ops;

static inline u64 axfs_get_node_type(struct axfs_super *sbi, u64 index)
{
	u64 depth = (sbi->node_type).table_byte_depth;
	u8 *vaddr = (u8 *) (sbi->node_type).virt_addr;

	return axfs_bytetable_stitch(depth, vaddr, index);
}

static inline u64 axfs_get_node_index(struct axfs_super *sbi, u64 index)
{
	u64 depth = (sbi->node_index).table_byte_depth;
	u8 *vaddr = (u8 *) (sbi->node_index).virt_addr;

	return axfs_bytetable_stitch(depth, vaddr, index);
}

static inline u64 axfs_is_node_xip(struct axfs_super *sbi, u64 index)
{
	if (axfs_get_node_type(sbi, index) == XIP)
		return true;

	return false;
}

static inline u64 axfs_get_cnode_index(struct axfs_super *sbi, u64 index)
{
	u64 depth = (sbi->cnode_index).table_byte_depth;
	u8 *vaddr = (u8 *) (sbi->cnode_index).virt_addr;

	return axfs_bytetable_stitch(depth, vaddr, index);
}

static inline u64 axfs_get_cnode_offset(struct axfs_super *sbi, u64 index)
{
	u64 depth = (sbi->cnode_offset).table_byte_depth;
	u8 *vaddr = (u8 *) (sbi->cnode_offset).virt_addr;

	return axfs_bytetable_stitch(depth, vaddr, index);
}

static inline u64 axfs_get_banode_offset(struct axfs_super *sbi, u64 index)
{
	u64 depth = (sbi->banode_offset).table_byte_depth;
	u8 *vaddr = (u8 *) (sbi->banode_offset).virt_addr;

	return axfs_bytetable_stitch(depth, vaddr, index);
}

static inline u64 axfs_get_cblock_offset(struct axfs_super *sbi, u64 index)
{
	u64 depth = (sbi->cblock_offset).table_byte_depth;
	u8 *vaddr = (u8 *) (sbi->cblock_offset).virt_addr;

	return axfs_bytetable_stitch(depth, vaddr, index);
}

static inline u64 axfs_get_inode_file_size(struct axfs_super *sbi, u64 index)
{
	u64 depth = (sbi->inode_file_size).table_byte_depth;
	u8 *vaddr = (u8 *) (sbi->inode_file_size).virt_addr;

	return axfs_bytetable_stitch(depth, vaddr, index);
}

u64 axfs_get_mode(struct axfs_super *sbi, u64 index)
{
	u64 mode = axfs_get_inode_mode_index(sbi, index);
	u64 depth = (sbi->modes).table_byte_depth;
	u8 *vaddr = (u8 *) (sbi->modes).virt_addr;

	return axfs_bytetable_stitch(depth, vaddr, mode);
}

u64 axfs_get_uid(struct axfs_super *sbi, u64 index)
{
	u64 mode = axfs_get_inode_mode_index(sbi, index);
	u64 depth = (sbi->uids).table_byte_depth;
	u8 *vaddr = (u8 *) (sbi->uids).virt_addr;

	return axfs_bytetable_stitch(depth, vaddr, mode);
}

u64 axfs_get_gid(struct axfs_super *sbi, u64 index)
{
	u64 mode = axfs_get_inode_mode_index(sbi, index);
	u64 depth = (sbi->gids).table_byte_depth;
	u8 *vaddr = (u8 *) (sbi->gids).virt_addr;

	return axfs_bytetable_stitch(depth, vaddr, mode);
}

u64 axfs_get_inode_name_offset(struct axfs_super *sbi, u64 index)
{
	u64 depth = (sbi->inode_name_offset).table_byte_depth;
	u8 *vaddr = (u8 *) (sbi->inode_name_offset).virt_addr;

	return axfs_bytetable_stitch(depth, vaddr, index);
}

u64 axfs_get_inode_num_entries(struct axfs_super *sbi, u64 index)
{
	u64 depth = (sbi->inode_num_entries).table_byte_depth;
	u8 *vaddr = (u8 *) (sbi->inode_num_entries).virt_addr;

	return axfs_bytetable_stitch(depth, vaddr, index);
}

u64 axfs_get_inode_mode_index(struct axfs_super *sbi, u64 index)
{
	u64 depth = (sbi->inode_mode_index).table_byte_depth;
	u8 *vaddr = (u8 *) (sbi->inode_mode_index).virt_addr;

	return axfs_bytetable_stitch(depth, vaddr, index);
}

u64 axfs_get_inode_array_index(struct axfs_super *sbi, u64 index)
{
	u64 depth = (sbi->inode_array_index).table_byte_depth;
	u8 *vaddr = (u8 *) (sbi->inode_array_index).virt_addr;

	return axfs_bytetable_stitch(depth, vaddr, index);
}

char *axfs_get_inode_name(struct axfs_super *sbi, u64 index)
{
	u64 ofs = axfs_get_inode_name_offset(sbi, index);
	u8 *virt = (sbi->strings).virt_addr;

	return (char *)(ofs + virt);
}

static inline u64 axfs_get_xip_region_physaddr(struct axfs_super *sbi)
{
	return sbi->phys_start_addr + sbi->xip.fsoffset;
}

static inline int axfs_region_is_vmalloc(struct axfs_super *sbi,
					 struct axfs_region_desc *region)
{
	u64 va = (u32) region->virt_addr;
	u64 vo = (u64) region->fsoffset + (u64) sbi->virt_start_addr;

	if (va == 0)
		return false;

	if (vo != va)
		return true;

	return false;
}

static int axfs_copy_data(struct super_block *sb, void *dst,
			  struct axfs_region_desc *region, u64 offset, u64 len)
{
	u64 mmapped = 0;
	u64 end = region->fsoffset + offset + len;
	u64 begin = region->fsoffset + offset;
	u64 left;
	void *addr;
	void *newdst;
	struct axfs_super *sbi = AXFS_SB(sb);

	if (len == 0)
		return 0;

	if (axfs_region_is_vmalloc(sbi, region)) {
		mmapped = len;
	} else if (region->virt_addr) {
		if (sbi->mmap_size >= end)
			mmapped = len;
		else if (sbi->mmap_size > begin)
			mmapped = sbi->mmap_size - begin;
	}

	if (mmapped) {
		addr = (void *)(region->virt_addr + offset);
		memcpy(dst, addr, mmapped);
	}

	newdst = (void *)(dst + mmapped);
	left = len - mmapped;

	if (left == 0)
		return len;

	if (axfs_has_bdev(sb))
		axfs_copy_block(sb, newdst, begin + mmapped, left);
	else if (axfs_has_mtd(sb))
		return axfs_copy_mtd(sb, newdst, begin + mmapped, left);

	return 0;
}

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,5,0)
static int axfs_iget5_test(struct inode *inode, void *opaque)
{
	u64 *inode_number = (u64 *) opaque;

	if (inode->i_sb == NULL) {
		printk(KERN_ERR "axfs_iget5_test:"
		       " the super block is set to null\n");
	}
	if (inode->i_ino == *inode_number)
		return 1;	/* matches */
	else
		return 0;	/* does not match */
}

static int axfs_iget5_set(struct inode *inode, void *opaque)
{
	u64 *inode_number = (u64 *) opaque;

	if (inode->i_sb == NULL) {
		printk(KERN_ERR "axfs_iget5_set:"
		       " the super block is set to null \n");
	}
	inode->i_ino = *inode_number;
	return 0;
}
#endif

struct inode *axfs_create_vfs_inode(struct super_block *sb, int ino)
{
	struct axfs_super *sbi = AXFS_SB(sb);
	struct inode *inode;
	u64 size;

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,5,0)
	inode = iget5_locked(sb, ino, axfs_iget5_test, axfs_iget5_set, &ino);

	if (!(inode && (inode->i_state & I_NEW)))
#else
	inode = new_inode(sb);

	if (!inode)
#endif
		return inode;

	inode->i_mode = axfs_get_mode(sbi, ino);
	inode->i_uid = axfs_get_uid(sbi, ino);
	size = axfs_get_inode_file_size(sbi, ino);
	inode->i_size = size;
	inode->i_blocks = axfs_get_inode_num_entries(sbi, ino);
	inode->i_blkbits = PAGE_CACHE_SIZE * 8;
	inode->i_gid = axfs_get_gid(sbi, ino);

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,5,0)
	inode->i_mtime = inode->i_atime = inode->i_ctime = sbi->timestamp;
#else
	inode->i_mtime = inode->i_atime = inode->i_ctime =
	    sbi->timestamp.tv_sec;
#endif
	inode->i_ino = ino;

	if (S_ISREG(inode->i_mode)) {
		inode->i_fop = &axfs_fops;
		inode->i_data.a_ops = &axfs_aops;
		inode->i_mapping->a_ops = &axfs_aops;
	} else if (S_ISDIR(inode->i_mode)) {
		inode->i_op = &axfs_dir_inode_operations;
		inode->i_fop = &axfs_directory_operations;
	} else if (S_ISLNK(inode->i_mode)) {
		inode->i_op = &page_symlink_inode_operations;
		inode->i_data.a_ops = &axfs_aops;
	} else {
		inode->i_size = 0;
		inode->i_blocks = 0;
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,5,0)
		init_special_inode(inode, inode->i_mode, old_decode_dev(size));
	}
	unlock_new_inode(inode);
#else
		init_special_inode(inode, inode->i_mode, to_kdev_t(size));
	}
#endif

	return inode;
}

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,5,0)
static int axfs_get_xip_mem(struct address_space *mapping, pgoff_t offset,
#else
static int axfs_get_xip_mem(struct address_space *mapping, unsigned long offset,
#endif
			    int create, void **kaddr, unsigned long *pfn)
{
	struct inode *inode = mapping->host;
	struct super_block *sb = inode->i_sb;
	struct axfs_super *sbi = AXFS_SB(sb);
	u64 ino_number = inode->i_ino;
	u64 ino_index, node_index;

	ino_index = axfs_get_inode_array_index(sbi, ino_number);
	ino_index += offset;

	node_index = axfs_get_node_index(sbi, ino_index);

	*kaddr = (void *)(sbi->xip.virt_addr + (node_index << PAGE_SHIFT));

	if (axfs_region_is_vmalloc(sbi, &(sbi->xip))) {
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,17)
		*pfn = vmalloc_to_pfn(*kaddr);
#else
		*pfn = page_to_pfn(virt_to_page(*kaddr));
#endif
	} else if (axfs_physaddr_is_valid(sbi)) {
		*pfn = (axfs_get_xip_region_physaddr(sbi) >> PAGE_SHIFT);
		*pfn += node_index;
	} else {
		*pfn = page_to_pfn(virt_to_page(*kaddr));
	}

	return 0;
}

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,25)
#else
static int axfs_insert_pfns(struct file *file, struct vm_area_struct *vma)
{
	struct inode *inode = file->f_dentry->d_inode;
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,5,0)
	struct address_space *mapping = file->f_mapping;
#else
	struct address_space *mapping = inode->i_mapping;
#endif
	struct super_block *sb = inode->i_sb;
	struct axfs_super *sbi = AXFS_SB(sb);
	unsigned long array_index, length, offset, count, addr, pfn;
	void *kaddr;
	unsigned int numpages;
	u64 ino_number = inode->i_ino;
	int error = 0;

	offset = vma->vm_pgoff;

	array_index = axfs_get_inode_array_index(sbi, ino_number);
	array_index += offset;
	length = vma->vm_end - vma->vm_start;

	if (length > inode->i_size)
		length = inode->i_size;

	length = PAGE_ALIGN(length);
	numpages = length >> PAGE_SHIFT;

	for (count = 0; count < numpages; count++, array_index++) {
		if (!axfs_is_node_xip(sbi, array_index))
			continue;
#ifdef VM_XIP
		vma->vm_flags |= (VM_IO | VM_XIP);
#endif
#ifdef VM_MIXEDMAP
		vma->vm_flags |= (VM_IO | VM_MIXEDMAP);
#endif
		addr = vma->vm_start + (PAGE_SIZE * count);
		axfs_get_xip_mem(mapping, offset + count, 0, &kaddr, &pfn);
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,5,0)
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,17)
		error = vm_insert_mixed(vma, addr, pfn);
#else
		error =
		    remap_pfn_range(vma, addr, pfn, PAGE_SIZE,
				    vma->vm_page_prot);
#endif
#else
		error =
		    remap_page_range(addr, pfn << PAGE_SHIFT, PAGE_SIZE,
				     vma->vm_page_prot);
#endif
		if (error)
			return error;
	}

	return 0;
}
#endif

static int axfs_mmap(struct file *file, struct vm_area_struct *vma)
{

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,5,0)
	file_accessed(file);
#endif

	vma->vm_ops = &axfs_vm_ops;

#ifdef VM_MIXEDMAP
#ifdef VM_CAN_NONLINEAR
	vma->vm_flags |= VM_CAN_NONLINEAR | VM_MIXEDMAP;
#else
	vma->vm_flags |= VM_IO | VM_MIXEDMAP;
#endif
#else
#ifdef VM_PFNMAP
	vma->vm_flags |= VM_IO | VM_PFNMAP;
#else
	vma->vm_flags |= VM_IO;
#endif
#endif
#ifdef VM_XIP
	vma->vm_flags |= VM_XIP;
#endif

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,25)
	return 0;
#else
	return axfs_insert_pfns(file, vma);
#endif
}

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,5,0)
/* The loop does a handful of things:
 * - First we see if they're the same length, if not we don't care.
 * - Then, we do a strncmp on two same-length strings:
 *  > -1 -> If the entry was in this directory, it would have been
 *	  right before this one.
 *  >  1 -> It's somewhere farther along in this directory.
 */
static struct dentry *axfs_lookup(struct inode *dir, struct dentry *dentry,
				  struct nameidata *nd)
#else
static struct dentry *axfs_lookup(struct inode *dir, struct dentry *dentry)
#endif
{
	struct super_block *sb = dir->i_sb;
	struct axfs_super *sbi = AXFS_SB(sb);
	u64 ino_number = dir->i_ino;
	u64 dir_index = 0;
	u64 entry;
	char *name;
	int namelen, err;

	while (dir_index < axfs_get_inode_num_entries(sbi, ino_number)) {
		entry = axfs_get_inode_array_index(sbi, ino_number);
		entry += dir_index;

		name = axfs_get_inode_name(sbi, entry);
		namelen = strlen(name);

		dir_index++;

		if (dentry->d_name.len != namelen)
			continue;

		err = strncmp(dentry->d_name.name, name, namelen);

		if (err < 0)
			break;

		if (err > 0)
			continue;

		d_add(dentry, axfs_create_vfs_inode(dir->i_sb, entry));
		goto out;

	}
	d_add(dentry, NULL);

out:
	return NULL;
}

static int axfs_readdir(struct file *filp, void *dirent, filldir_t filldir)
{
	struct inode *inode = filp->f_dentry->d_inode;
	struct super_block *sb = inode->i_sb;
	struct axfs_super *sbi = AXFS_SB(sb);
	u64 ino_number = inode->i_ino;
	u64 entry;
	loff_t dir_index;
	char *name;
	int namelen, mode;
	int err = 0;

	/* Get the current index into the directory and verify it is not beyond
	   the end of the list */
	dir_index = filp->f_pos;
	if (dir_index >= axfs_get_inode_num_entries(sbi, ino_number))
		goto out;

	while (dir_index < axfs_get_inode_num_entries(sbi, ino_number)) {
		entry = axfs_get_inode_array_index(sbi, ino_number) + dir_index;

		name = axfs_get_inode_name(sbi, entry);
		namelen = strlen(name);

		mode = (int)axfs_get_mode(sbi, entry);
		err = filldir(dirent, name, namelen, dir_index, entry, mode);

		if (err)
			break;

		dir_index++;
		filp->f_pos = dir_index;
	}

out:
	return 0;
}

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,22)
/******************************************************************************
 *
 * axfs_fault
 *
 * Description: This function is mapped into the VMA operations vector, and
 *	      gets called on a page fault. Depending on whether the page
 *	      is XIP or compressed, xip_file_fault or filemap_fault is
 *	      called.  This function also logs when a fault occurs when
 *	      profiling is on.
 *
 * Parameters:
 *    (IN) vma  - The virtual memory area corresponding to a file
 *
 *    (IN) vmf  - The fault info pass in by the fault handler
 *
 * Returns:
 *    0 or error number
 *
 *****************************************************************************/
static int axfs_fault(struct vm_area_struct *vma, struct vm_fault *vmf)
#else
static struct page *axfs_nopage(struct vm_area_struct *vma,
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,5,0)
				unsigned long address, int *type)
#else
				unsigned long address, int type)
#endif
#endif
{
	struct file *file = vma->vm_file;
	struct inode *inode = file->f_dentry->d_inode;
	struct super_block *sb = inode->i_sb;
	struct axfs_super *sbi = AXFS_SB(sb);
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,22)
#else
	unsigned long pgoff;
#endif
	u64 ino_number = inode->i_ino;
	u64 array_index;

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,22)
	array_index = axfs_get_inode_array_index(sbi, ino_number) + vmf->pgoff;
#else
	pgoff = ((address - vma->vm_start) >> PAGE_CACHE_SHIFT) + vma->vm_pgoff;
	array_index = axfs_get_inode_array_index(sbi, ino_number) + pgoff;
#endif

	/* if that pages are marked for write they will probably end up in RAM
	   therefore we don't want their counts for being XIP'd */
	if (!(vma->vm_flags & VM_WRITE))
		axfs_profiling_add(sbi, array_index, ino_number);

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,12)
	/* figure out if the node is XIP or compressed and call the
	   appropriate function
	 */
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,25)
	if (axfs_is_node_xip(sbi, array_index))
#else
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,17)
	if (axfs_is_node_xip(sbi, array_index) && !axfs_physaddr_is_valid(sbi))
#else
	if (!(axfs_is_pointed(sbi) && !axfs_physaddr_is_valid(sbi)))
#endif
#endif
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,22)
		return xip_file_fault(vma, vmf);
#else
		return xip_file_nopage(vma, address, type);
#endif
#endif
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,22)
	return filemap_fault(vma, vmf);
#else
	return filemap_nopage(vma, address, type);
#endif
}

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,12)
#else
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,5,0)
static ssize_t axfs_xip_file_read(struct file *file, char __user * buf,
#else
static ssize_t axfs_xip_file_read(struct file *file, char *buf,
#endif
				  size_t len, loff_t *ppos)
{
	struct inode *inode = file->f_dentry->d_inode;
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,5,0)
	struct address_space *mapping = file->f_mapping;
#else
	struct address_space *mapping = inode->i_mapping;
#endif
	unsigned long index, end_index, offset;
	loff_t isize, pos;
	size_t copied = 0, error = 0;

	pos = *ppos;
	index = pos >> PAGE_CACHE_SHIFT;
	offset = pos & ~PAGE_CACHE_MASK;

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,5,0)
	isize = i_size_read(inode);
#else
	isize = inode->i_size;
#endif
	if (!isize)
		goto out;

	end_index = (isize - 1) >> PAGE_CACHE_SHIFT;
	do {
		unsigned long nr, left, pfn;
		void *xip_mem;
		int zero = 0;

		/* nr is the maximum number of bytes to copy from this page */
		nr = PAGE_CACHE_SIZE;
		if (index >= end_index) {
			if (index > end_index)
				goto out;
			nr = ((isize - 1) & ~PAGE_CACHE_MASK) + 1;
			if (nr <= offset)
				goto out;
		}
		nr = nr - offset;
		if (nr > len)
			nr = len;
		axfs_get_xip_mem(mapping, index, 0, &xip_mem, &pfn);
		if (!xip_mem) {
			error = -EIO;
			goto out;
		}
		if (unlikely(IS_ERR(xip_mem))) {
			if (PTR_ERR(xip_mem) == -ENODATA) {
				/* sparse */
				zero = 1;
			} else {
				error = PTR_ERR(xip_mem);
				goto out;
			}
		}
		/*
		 * Ok, we have the mem, so now we can copy it to user space...
		 *
		 * The actor routine returns how many bytes were actually used..
		 * NOTE! This may not be the same as how much of a user buffer
		 * we filled up (we may be padding etc), so we can only update
		 * "pos" here (the actor routine has to update the user buffer
		 * pointers and the remaining count).
		 */
		if (!zero)
			left =
			    __copy_to_user(buf + copied, xip_mem + offset, nr);
		else
			left = __clear_user(buf + copied, nr);

		if (left) {
			error = -EFAULT;
			goto out;
		}

		copied += (nr - left);
		offset += (nr - left);
		index += offset >> PAGE_CACHE_SHIFT;
		offset &= ~PAGE_CACHE_MASK;
	} while (copied < len);

out:
	*ppos = pos + copied;
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,5,0)
	if (file)
		file_accessed(file);
#endif

	return copied ? copied : error;
}
#endif

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,5,0)
/******************************************************************************
 *
 * axfs_file_read
 *
 * Description: axfs_file_read is mapped into the file_operations vector for
 *	      all axfs files. It loops through the pages to be read and calls
 *	      either do_sync_read (if the page is a compressed one) or
 *	      xip_file_read (if the page is XIP).
 *
 * Parameters:
 *    (IN) filp -  file to be read
 *
 *    (OUT) buf - user buffer that is filled with the data that we read.
 *
 *    (IN) len - length of file to be read
 *
 *    (IN) ppos - offset within the file to read from
 *
 * Returns:
 *    actual size of data read.
 *
 *****************************************************************************/
static ssize_t axfs_file_read(struct file *filp, char __user *buf, size_t len,
			      loff_t *ppos)
#else
static ssize_t axfs_file_read(struct file *filp, char *buf, size_t len,
			      loff_t *ppos)
#endif
{
	struct inode *inode = filp->f_dentry->d_inode;
	struct super_block *sb = inode->i_sb;
	struct axfs_super *sbi = AXFS_SB(sb);
	size_t read = 0, total_read = 0;
	size_t readlength, actual_size, file_size, remaining;
	u64 ino_number = inode->i_ino;
	u64 size, array_index;

	file_size = axfs_get_inode_file_size(sbi, ino_number);
	remaining = file_size - *ppos;
	actual_size = len > remaining ? remaining : len;
	readlength = actual_size < PAGE_SIZE ? actual_size : PAGE_SIZE;

	for (size = actual_size; size > 0; size -= read) {
		array_index = axfs_get_inode_array_index(sbi, ino_number);
		array_index += *ppos >> PAGE_SHIFT;

		if (axfs_is_node_xip(sbi, array_index)) {
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,12)
			read = xip_file_read(filp, buf, readlength, ppos);
#else
			read = axfs_xip_file_read(filp, buf, readlength, ppos);
#endif
		} else {
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,5,0)
			read = do_sync_read(filp, buf, readlength, ppos);
#else
			read = generic_file_read(filp, buf, readlength, ppos);
#endif

		}
		buf += read;
		total_read += read;

		if ((len - total_read < PAGE_SIZE) && (total_read != len))
			readlength = len - total_read;
	}

	return total_read;
}

static int axfs_readpage(struct file *file, struct page *page)
{
	struct inode *inode = page->mapping->host;
	struct super_block *sb = inode->i_sb;
	struct axfs_super *sbi = AXFS_SB(sb);
	u64 array_index, node_index, cnode_index, maxblock, ofs;
	u64 ino_number = inode->i_ino;
	u32 max_len, cnode_offset;
	u32 cblk_size = sbi->cblock_size;
	u32 len = 0;
	u8 node_type;
	void *pgdata;
	void *src;
	void *cblk0 = sbi->cblock_buffer[0];
	void *cblk1 = sbi->cblock_buffer[1];

	maxblock = (inode->i_size + PAGE_CACHE_SIZE - 1) >> PAGE_CACHE_SHIFT;
	pgdata = kmap(page);

	if (page->index >= maxblock)
		goto out;

	array_index = axfs_get_inode_array_index(sbi, ino_number);
	array_index += page->index;

	node_index = axfs_get_node_index(sbi, array_index);
	node_type = axfs_get_node_type(sbi, array_index);

	if (node_type == Compressed) {
		/* node is in compessed region */
		cnode_offset = axfs_get_cnode_offset(sbi, node_index);
		cnode_index = axfs_get_cnode_index(sbi, node_index);
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,5,0)
#else
retry:
#endif
		down_write(&sbi->lock);
		if (cnode_index != sbi->current_cnode_index) {
			/* uncompress only necessary if different cblock */
			ofs = axfs_get_cblock_offset(sbi, cnode_index);
			len = axfs_get_cblock_offset(sbi, cnode_index + 1);
			len -= ofs;
			axfs_copy_data(sb, cblk1, &(sbi->compressed), ofs, len);
			axfs_uncompress_block(cblk0, cblk_size, cblk1, len);
			sbi->current_cnode_index = cnode_index;
		}
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,5,0)
		downgrade_write(&sbi->lock);
#else
		up_write(&sbi->lock);
		down_read(&sbi->lock);
		if (cnode_index != sbi->current_cnode_index) {
			up_read(&sbi->lock);
			goto retry;
		}
#endif
		max_len = cblk_size - cnode_offset;
		len = max_len > PAGE_CACHE_SIZE ? PAGE_CACHE_SIZE : max_len;
		src = (void *)((unsigned long)cblk0 + cnode_offset);
		memcpy(pgdata, src, len);
		up_read(&sbi->lock);
	} else if (node_type == Byte_Aligned) {
		/* node is in BA region */
		ofs = axfs_get_banode_offset(sbi, node_index);
		max_len = sbi->byte_aligned.size - ofs;
		len = max_len > PAGE_CACHE_SIZE ? PAGE_CACHE_SIZE : max_len;
		axfs_copy_data(sb, pgdata, &(sbi->byte_aligned), ofs, len);
	} else {
		/* node is XIP */
		ofs = node_index << PAGE_SHIFT;
		len = PAGE_CACHE_SIZE;
		axfs_copy_data(sb, pgdata, &(sbi->xip), ofs, len);
	}

out:
	memset(pgdata + len, 0, PAGE_CACHE_SIZE - len);
	kunmap(page);
	flush_dcache_page(page);
	SetPageUptodate(page);
	unlock_page(page);
	return 0;
}

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,12)
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,25)
#else
struct page *axfs_get_xip_page(struct address_space *mapping, sector_t offset,
			       int create)
{
	unsigned long pfn;
	void *kaddr;
	pgoff_t pgoff;

	pgoff = (offset * 512) >> PAGE_SHIFT;

	axfs_get_xip_mem(mapping, pgoff, create, &kaddr, &pfn);

	return virt_to_page(kaddr);
}
#endif
#endif

static const struct file_operations axfs_directory_operations = {
	.llseek = generic_file_llseek,
	.read = generic_read_dir,
	.readdir = axfs_readdir,
};

static const struct file_operations axfs_fops = {
	.read = axfs_file_read,
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,5,0)
	.aio_read = generic_file_aio_read,
#endif
	.mmap = axfs_mmap,
};

static struct address_space_operations axfs_aops = {
	.readpage = axfs_readpage,
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,25)
	.get_xip_mem = axfs_get_xip_mem,
#else
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,12)
	.get_xip_page = axfs_get_xip_page,
#endif
#endif
};

static struct inode_operations axfs_dir_inode_operations = {
	.lookup = axfs_lookup,
};

static struct vm_operations_struct axfs_vm_ops = {
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,22)
	.fault = axfs_fault,
#else
	.nopage = axfs_nopage,
#endif
};

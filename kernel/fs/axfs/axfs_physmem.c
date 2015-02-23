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
 * axfs_physmem.c -
 *   Allows axfs to use striaght memory or has dummy functions if
 *   this is a UML system.
 */
#include "axfs.h"

#include <linux/fs.h>
#ifdef CONFIG_UML

void axfs_map_physmem(struct axfs_super *sbi, unsigned long size)
{
}

void axfs_unmap_physmem(struct super_block *sb)
{
}

#else
#include <asm/io.h>
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,21)
#else
#include <asm/pgtable.h>
#endif

#ifdef ioremap_cached
#define AXFS_REMAP(a,b) (void __force *)ioremap_cached((a),(b))
#else
#define AXFS_REMAP(a,b) (void __force *)ioremap((a),(b))
#endif /* ioremap_cached */

void axfs_map_physmem(struct axfs_super *sbi, unsigned long size)
{
	void *addr;

	if (axfs_is_physmem(sbi)) {
		addr = AXFS_REMAP(sbi->phys_start_addr, size);
		sbi->virt_start_addr = (unsigned long)addr;
	}
}

void axfs_unmap_physmem(void *addr)
{
	if( !addr )
		return;

	iounmap(addr);
}

void *axfs_get_physmem_addr(struct super_block *sb)
{
	struct axfs_super *sbi = AXFS_SB(sb);

	if (!sbi)
		return NULL;

	if (!axfs_is_physmem(sbi))
		return NULL;

	if(!axfs_virtaddr_is_valid(sbi))
		return NULL;

	return (void *)(sbi->virt_start_addr);
}

#endif /* CONFIG_UML */

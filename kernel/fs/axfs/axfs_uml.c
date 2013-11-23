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
 * axfs_uml.c -
 *   Allows axfs to a UML kernels find_iomem() interface as an XIP device or
 *   dummy functions if this is not a UML build.
 */
#include "axfs.h"

#ifdef CONFIG_UML
#include <mem_user.h>
int axfs_get_uml_address(char *iomem, unsigned long *address,
			 unsigned long *length)
{
	*address = find_iomem(iomem, length);
	if (!(*address)) {
		printk(KERN_DEBUG "axfs: find_iomem() failed\n");
		return -EINVAL;
	}

	if (*length < PAGE_SIZE) {
		printk(KERN_DEBUG
		       "axfs: iomem() too small, must be at least %li Bytes\n",
		       PAGE_SIZE);
		return -EINVAL;
	}
	return 0;
}
#else
int axfs_get_uml_address(char *iomem, unsigned long *address,
			 unsigned long *length)
{
	return 0;
}
#endif /* CONFIG_UML */

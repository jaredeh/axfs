/*
 * Advanced XIP File System for Linux - AXFS
 *   Readonly, compressed, and XIP filesystem for Linux systems big and small
 *
 *   Modified in 2006 by Eric Anderson
 *     from the cramfs sources fs/cramfs/uncompress.c
 *
 * (C) Copyright 1999 Linus Torvalds
 *
 * axfs_uncompress.c -
 *  axfs interfaces to the uncompression library. There's really just
 * three entrypoints:
 *
 *  - axfs_uncompress_init() - called to initialize the thing.
 *  - axfs_uncompress_exit() - tell me when you're done
 *  - axfs_uncompress_block() - uncompress a block.
 *
 * NOTE NOTE NOTE! The uncompression is entirely single-threaded. We
 * only have one stream, and we'll initialize it only once even if it
 * then is used by multiple filesystems.
 *
 */

#ifndef ALL_VERSIONS
#include <linux/version.h>	/* For multi-version support */
#endif
#include <linux/errno.h>
#include <linux/vmalloc.h>
#include <linux/zlib.h>
#include <linux/init.h>
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,15)
#include <linux/mutex.h>
#else
#include <linux/rwsem.h>
#endif

static z_stream stream;
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,15)
static DEFINE_MUTEX(axfs_uncmp_mutex);
#else
static struct rw_semaphore axfs_uncmp_mutex;
#endif

int axfs_uncompress_block(void *dst, int dstlen, void *src, int srclen)
{
	int err;
	int out;

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,15)
	mutex_lock(&axfs_uncmp_mutex);
#else
	down_write(&axfs_uncmp_mutex);
#endif

	stream.next_in = src;
	stream.avail_in = srclen;

	stream.next_out = dst;
	stream.avail_out = dstlen;

	err = zlib_inflateReset(&stream);
	if (err != Z_OK) {
		printk(KERN_ERR "axfs: zlib_inflateReset error %d\n", err);
		zlib_inflateEnd(&stream);
		zlib_inflateInit(&stream);
	}

	err = zlib_inflate(&stream, Z_FINISH);
	if (err != Z_STREAM_END)
		goto err;

	out = stream.total_out;

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,15)
	mutex_unlock(&axfs_uncmp_mutex);
#else
	up_write(&axfs_uncmp_mutex);
#endif

	return out;

err:

#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,15)
	mutex_unlock(&axfs_uncmp_mutex);
#else
	up_write(&axfs_uncmp_mutex);
#endif

	printk(KERN_ERR "axfs: error %d while decompressing!\n", err);
	printk(KERN_ERR "%p(%d)->%p(%d)\n", src, srclen, dst, dstlen);
	return 0;
}

int __init axfs_uncompress_init(void)
{
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,15)
#else
	init_rwsem(&axfs_uncmp_mutex);
#endif

	stream.workspace = vmalloc(zlib_inflate_workspacesize());
	if (!stream.workspace)
		return -ENOMEM;
	stream.next_in = NULL;
	stream.avail_in = 0;
	zlib_inflateInit(&stream);

	return 0;
}

int axfs_uncompress_exit(void)
{
	zlib_inflateEnd(&stream);
	vfree(stream.workspace);
	return 0;
}

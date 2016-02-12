/*
 * mkfs tool for AXFS filesystem
 *
 * Copyright(c) 2008 Numonyx
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms and conditions of the GNU General Public License,
 * version 2, as published by the Free Software Foundation.
 *
 */

#include<sys/types.h>
#include<stdio.h>
#include<sys/stat.h>
#include<unistd.h>
#include<sys/mman.h>
#include<fcntl.h>
#include<dirent.h>
#include<stdlib.h>
#include<errno.h>
#include<string.h>
#include<stdarg.h>
#include<netinet/in.h>
#include<stdint.h>
#include<endian.h>
#include<byteswap.h>

#define AXFS_VERSION_MAJOR 2
#define AXFS_VERSION_MINOR 2
#define AXFS_VERSION_SUB 0

#ifndef htonll
#if __BYTE_ORDER == __BIG_ENDIAN
#define htonll(x) (x)
#else
#define htonll(x) bswap_64(x)
#endif
#endif

#ifndef ntohll
#if __BYTE_ORDER == __BIG_ENDIAN
#define ntohll(x) (x)
#else
#define ntohll(x) bswap_64(x)
#endif
#endif

#define cpu_to_be32 htonl
#define cpu_to_be64 htonll

#define be32_to_cpu ntohl
#define be64_to_cpu ntohll

struct rw_semaphore {};

#define u8     uint8_t
#define u16    uint16_t
#define u32    uint32_t
#define u64    uint64_t

#include<linux/axfs.h>
#include<zlib.h>

/* Exit codes used by mkfs-type programs */
#define MKFS_OK		0	/* No errors */
#define MKFS_ERROR	8	/* Operational error */
#define MKFS_USAGE	16	/* Usage or syntax error */
#define PARSE_OK	1	/* No parse errors */
#define PARSE_ERROR	2	/* Parse error */

/* The kernel assumes PAGE_CACHE_SIZE as block size. */
#define PAGE_CACHE_SIZE (4096)
#define PAGE_ALIGN(addr) ((addr+PAGE_CACHE_SIZE-1)&(~(PAGE_CACHE_SIZE-1)))

#define MAX_INPUT_NAMELEN 255

/* Raw entry extracted from a CSV file */
typedef struct xipentry {
	char *path;
	u32 offset;
	u32 count;
} xipentry, *xipentryPtr;

/* Info of a chunk to be XIPed */
typedef struct xipchunk {
	u32 size;
	u32 offset;
} xipchunk, *xipchunkPtr;

/* A file with xip chunks */
typedef struct xipfile {
	char *path;
	u32 chunknb;
	u32 index; /* index of the first chunk */
} xipfile, *xipfilePtr;

/* In-core version of inode / directory entry. */
struct entry {
	u8 *name;
	/* stats */
	u32 mode_index;
	u32 size;

	/* these are only used for non-empty files */
	char *path;	/* always null except non-empty files */
	int fd;		/* temporarily open files while mmapped */
	void *uncompressed; /* FS data */
	u8 mallocd;
	u8 *bitmap;	/* XIP info */

	/* points to other identical file */
	struct entry *same;

	/* organization */
	struct entry *child; /* null for non-directories and empty directories */
	struct entry *next;
	u32 total_entries; /* for dir: # of children; for file: # of node */

	/* for non-empty file only, offset to the node table */
	u32 array_offset;
	u8 array_offset_set;
};

struct dir_list_element {
	struct entry * data;
	struct dir_list_element * next;
};

struct dir_list {
	int size;
	struct dir_list_element * head;
	struct dir_list_element * last;
};

struct axfs_mode_bits {
	u32 mode;
	u32 uid;
	u32 gid;
};

/*
 * Total # of files with XIP chunks
 * and total # of chunks to be XIPed
 */
static u32 total_xipfiles, total_xipchunks;
static u32 next_xipchunk;

/*
 * Array for all xip chunks
 * and array for all valid xip files
 */
static xipchunkPtr xipchunkset = NULL;
static xipfilePtr xipfileset = NULL;

static const char *progname = "mkfs.axfs";
static unsigned int blksize = PAGE_CACHE_SIZE;

static int warn_skip;

/* Super block */
//static struct axfs_super_onmedia sb;

struct axfs_mode_bits **mode_index = NULL;

/* Total # of nodes and total # of inodes */
static u32 total_nodes; /* one node for one block */
static u32 total_inodes; /* one inode for one file/dir */
static u32 total_xipnodes;
static u32 total_size = 0;

/* Name size including '/0' */
static u32 total_namesize;
static u32 total_modes = 0;

u32 xip_all_files = 0;
u32 xip_entire_file = 0;
u32 silent = 0;
u32 entry_count = 0;
struct entry **entry_table = NULL;

struct axfs_region_desc strings_rd;
struct axfs_region_desc xip_rd;
struct axfs_region_desc byte_aligned_rd;
struct axfs_region_desc compressed_rd;
struct axfs_region_desc node_type_rd;
struct axfs_region_desc node_index_rd;
struct axfs_region_desc cnode_offset_rd;
struct axfs_region_desc cnode_index_rd;
struct axfs_region_desc banode_offset_rd;
struct axfs_region_desc cblock_offset_rd;
struct axfs_region_desc inode_file_size_rd;
struct axfs_region_desc inode_name_offset_rd;
struct axfs_region_desc inode_num_entries_rd;
struct axfs_region_desc inode_mode_index_rd;
struct axfs_region_desc inode_array_index_rd;
struct axfs_region_desc modes_rd;
struct axfs_region_desc uids_rd;
struct axfs_region_desc gids_rd;
struct axfs_region_desc super_rd;
struct axfs_region_desc endpadding_rd;
struct axfs_region_desc xippadding_rd;

/*****************************************************************************
 *
 * process_four_byte_table
 *
 * Description:
 *    Takes an array of u32's and creates a byte_table into a region
 *
 * Parameters:
 *    An axfs_region_desc.
 *    An array of u32 values.
 *    The number of values in the u32 array.
 *
 * Returns:
 *    No return, axfs_region_desc->virt_addr should now contain an array
 *    of count * sizeof(u32) u8 values.
 *
 * Assumptions:
 *    The u32 values have been properly formatted.
 *    The axfs_region_desc has been allocated.
 *
 ****************************************************************************/
static void process_four_byte_table(struct axfs_region_desc *region, u32 *array, int count)
{
	int i,j;
	u8 * virtaddr;
	region->table_byte_depth = 4;
	region->max_index = count;
	region->size = count * 4;
	region->virt_addr = malloc(region->size + 1);
	memset(region->virt_addr,0,region->size + 1);
	virtaddr = (u8 *)region->virt_addr;

	for(i=0;i<count;i++){
		*virtaddr = (u8)(array[i]>>  24);
		virtaddr++;

		*virtaddr = (u8)(array[i]>>  16);
		virtaddr++;

		*virtaddr = (u8)(array[i]>>  8);
		virtaddr++;

		*virtaddr = (u8)array[i];
		virtaddr++;
	}

}

/*****************************************************************************
 *
 * process_one_byte_table
 *
 * Description:
 *    Takes an array of u8's and creates a byte_table into a region
 *
 * Parameters:
 *
 * Returns:
 *
 * Assumptions:
 *
 ****************************************************************************/
static void process_one_byte_table(struct axfs_region_desc *region, u8 *array, int count)
{
	int i;
	u8 * virtaddr;

	region->table_byte_depth = 1;
	region->max_index = count;
	region->size = count;
	region->virt_addr = malloc(region->size + 1);
	memset(region->virt_addr,0,region->size + 1);
	virtaddr = (u8 *)region->virt_addr;

	for(i=0;i<count;i++){
		*virtaddr = (u8)array[i];
		virtaddr++;
	}
}

/*****************************************************************************
 *
 * usage
 *
 * Description:
 *    Prints out the usage of this tool.
 *
 * Parameters:
 *
 * Returns:
 *
 * Assumptions:
 *
 ****************************************************************************/
static void usage(int status)
{
	FILE *stream = status ? stderr : stdout;

	fprintf(stream, "usage: %s [-h] [-i infile] dirname outfile\n"
		" -h            print this help\n"
		" -i infile     input file of the XIP information\n"
		" -n outfile    output inode number/name list\n"
		" -s            run silently\n"
		" -a            xip all files (no input file needed)\n"
		" -e            for any file in '-i infile', xip the entire file automatically\n"
		" dirname	root of the directory tree to be compressed\n"
		" outfile	output file\n", progname);

	exit(status);
}

/*****************************************************************************
 *
 * die
 *
 * Description:
 *    Reports the error and exits.
 *
 * Parameters:
 *
 * Returns:
 *
 * Assumptions:
 *
 ****************************************************************************/
static void die(int status, int syserr, const char *fmt, ...)
{
	va_list arg_ptr;
	int save = errno;

	fflush(0);
	va_start(arg_ptr, fmt);
	fprintf(stderr, "%s: ", progname);
	vfprintf(stderr, fmt, arg_ptr);
	if (syserr) {
		fprintf(stderr, ": %s", strerror(save));
	}
	fprintf(stderr, "\n");
	va_end(arg_ptr);
	exit(status);
}

/*****************************************************************************
 *
 * split_on_token
 *
 * Description:
 *    Parses a string and returns an array of strings split on the supplied
 *    token.
 *
 * Parameters:
 *    (IN) src - Pointer to a string.
 *    (OUT) count - Number of strings extracted.
 *    (IN) token - Single character specifying the token to split on.
 *
 * Returns:
 *    An array of strings;
 *
 * Assumptions:
 *
 ****************************************************************************/
static char** split_on_token(char *src, int *count, char *token)
{
	char **dst = NULL;
	char **ptr = NULL;
	char *line = NULL;
	int i,p;

	line = strtok(src, token);
	for(i = 0; line != NULL; i++) {
		ptr = dst;
		dst = (char**) malloc(sizeof(char*) * (i+1));
		for (p = 0; p<  i; p++)
			dst[p] = ptr[p];
		free(ptr);
		dst[i] = line;
		line = strtok(NULL, token);
	}

	*count = i;
	return dst;
}

static void list_entries(char **lines, int count, struct xipentry *entries, char *dirname)
{
	char **entrybuf = NULL;
	char token[] = ",";
	int i, items_per_line, size = 0;
	char *nbuf = NULL;
	int fname_offset = 0;

	for(i = 0; i<  count; i++) {
		entrybuf = split_on_token(lines[i],&items_per_line, token);
		if( (entrybuf[0][0] == '.') &&  (entrybuf[0][1] == '/'))
			fname_offset = 2;
		size += (strlen(dirname) + strlen(&(entrybuf[0][fname_offset]))) + 1;
		size *= sizeof(char);
		entries[i].path = (char*) malloc(size);
		sprintf(entries[i].path,"%s%s",dirname,&(entrybuf[0][fname_offset]));
		entries[i].offset = atoi(entrybuf[1]);
		entries[i].count = atoi(entrybuf[2]);
	}
}

static int count_unique_files(struct xipentry *entries, int num_entries)
{
	int fcount = 0, i, j;

	for (i = 0; i<  num_entries; i++) {
		if (fcount == 0) {
			fcount = 1;
			continue;
		}

		for (j = 0; j<  i; j++) {
			if (strcmp(entries[i].path, entries[j].path) == 0)
				goto drop;
		}

		fcount++;
drop:
		continue;
	}

	return fcount;
}

static int known_file(char *entry)
{
	int i;

	for (i = 0; i<  total_xipfiles; i++) {

		if (xipfileset[i].path == NULL)
			return 0;
		if (strncmp(entry,xipfileset[i].path,strlen(entry)) == 0)
			return 1;
	}
}

static int get_free_file()
{
	int i;

	for (i = 0; i<  total_xipfiles; i++) {
		if (xipfileset[i].path == NULL)
			return i;
	}
}

static int chunk_of_file(int index, struct xipentry *entry)
{
	if (strncmp(xipfileset[index].path,entry->path,strlen(entry->path)) == 0)
		return 1;
	else
		return 0;
}

static void populate_sets(struct xipentry *entries, char *dirname)
{
	int i, j, k;
	struct xipfile *cfile;
	int fileind;
	int chunkind;
	int index = 0;

	char *ename = NULL;

	for ( i = 0; i < total_xipchunks; i++) {
		ename = entries[i].path;

		/* Look for a file we have not added yet */
		if (!known_file(ename)) {
			index = get_free_file();
			xipfileset[index].path = (char*) malloc(strlen(ename));
			sprintf(xipfileset[index].path,"%s",ename);
			xipfileset[index].chunknb = 0;
			if (index>  0)
				xipfileset[index].index = xipfileset[index-1].index + xipfileset[index-1].chunknb;

			/* Run through and find all the XIP chunks for this file */
			for (j = i; j < total_xipchunks; j++) {
				if (chunk_of_file(index,&entries[j])) {
					chunkind = xipfileset[index].index + xipfileset[index].chunknb;
					xipchunkset[chunkind].size = 4096;
					xipchunkset[chunkind].offset = entries[j].offset;
					xipfileset[index].chunknb = xipfileset[index].chunknb + 1;
				}
			}
		}
	}
}

void free_entries(struct xipentry *entries)
{
	int i;
	struct xipentry *entry;

	for (i = 0; i<  total_xipchunks; i++) {
		entry =&(entries[i]);
		free(entry->path);
	}
	total_xipchunks = 0;
}

/*****************************************************************************
 *
 * parseInfile
 *
 * Description:
 *    Parses the input CSV file.  Generates the global array for
 *    xipfileset[] and xipchunkset[].
 *
 * Parameters:
 *    (IN) filename - file name of the input CSV file
 *
 *    (IN) dirname - path of the root directory
 *
 * Returns:
 *    PARSE_OK
 *    PARSE_ERROR
 *
 * Assumptions:
 *
 ****************************************************************************/
static int parseInfile(char *filename, char *dirname)
{
	int profile;
	struct stat filestat;
	int totalchunks = 0, totalfiles = 0;
	char *buf;
	char **lines;
	struct xipentry *entries;
	int err, filesize,i;

	/* Get File Size */
	profile = open(filename, O_RDONLY);
	fstat(profile, &filestat);
	filesize = filestat.st_size;

	/* Read entire file */
	buf = (char*) malloc(sizeof(char)*filesize+1);
	read(profile, buf, filesize);
	buf[filesize] = 0;

	/* Allocate 1 XIP entry per line */
	lines = split_on_token(buf,&total_xipchunks, "\n");
	entries = (xipentry*) malloc(sizeof(xipentry)*total_xipchunks);
	xipchunkset = (xipchunkPtr) malloc(sizeof(xipchunk)*total_xipchunks);
	memset(xipchunkset, 0, sizeof(xipchunk)*total_xipchunks);

	/* fill out entires */
	list_entries(lines, total_xipchunks, entries, dirname);

	/* Allcate 'xipfile' entries, then add them to xipfileset[] */
	total_xipfiles = count_unique_files(entries, total_xipchunks);
	xipfileset = (xipfilePtr) malloc(sizeof(xipfile)*total_xipfiles);
	memset(xipfileset, 0, sizeof(xipfile)*total_xipfiles);

	populate_sets(entries, dirname);

	free_entries(entries);
	free(entries);
	return PARSE_OK;
}
/*****************************************************************************
 *
 * map_entry
 *
 * Description:
 *    Reads the uncompressed file data.
 *
 * Parameters:
 *    (IN) entry - file entry
 *
 * Returns:
 *
 * Assumptions:
 *
 ****************************************************************************/
static void map_entry(struct entry *entry)
{
	if (entry->path) {
		entry->fd = open(entry->path, O_RDONLY);
		if (entry->fd<  0) {
			die(MKFS_ERROR, 1, "open failed: %s", entry->path);
		}
		entry->uncompressed = mmap(NULL, entry->size, PROT_READ,MAP_PRIVATE, entry->fd, 0);
		if (entry->uncompressed == MAP_FAILED) {
			die(MKFS_ERROR, 1, "mmap failed: %s", entry->path);
		}
	}
}

/*****************************************************************************
 *
 * unmap_entry
 *
 * Description:
 *    Frees the entry buffer and close the file.
 *
 * Parameters:
 *    (IN) entry - file entry
 *
 * Returns:
 *
 * Assumptions:
 *
 ****************************************************************************/
static void unmap_entry(struct entry *entry)
{
	if (entry->path) {
		if (munmap(entry->uncompressed, entry->size)<  0) {
			die(MKFS_ERROR, 1, "munmap failed: %s", entry->path);
		}
		close(entry->fd);
	}
}

/*****************************************************************************
 *
 * find_identical_file
 *
 * Description:
 *    Finds any identical file of the orig file in the root directory.
 *
 * Parameters:
 *    (IN) orig - entry of the original file
 *    (IN) newfile - entry of the identical file
 *
 * Returns:
 *    0 - there is no identical file
 *    1 - identical file exists
 *
 * Assumptions:
 *
 ****************************************************************************/
static int find_identical_file(struct entry *orig, struct entry *newfile)
{
return 0;	//BUG: Symlink files not handled correctly! (Fix later)

	if (orig == newfile)
		return 1;
	if (!orig)
		return 0;

	if (orig == newfile)
		return 1;

	if ( (orig->size == newfile->size) && (orig->path || orig->uncompressed)) {
		map_entry(orig);
		map_entry(newfile);
		if (!memcmp(orig->uncompressed, newfile->uncompressed, orig->size)) {
			newfile->same = orig;
			total_nodes -= orig->total_entries;
			unmap_entry(newfile);
			unmap_entry(orig);
			return 1;
		}
		unmap_entry(newfile);
		unmap_entry(orig);
	}

	return (find_identical_file(orig->next, newfile) || find_identical_file(orig->child, newfile));
}

/*****************************************************************************
 *
 * eliminate_doubles
 *
 * Description:
 *    Eliminates identical files in the root directory.
 *
 * Parameters:
 *    (IN) root - entry of the root directory
 *    (IN) orig - entry of the original file
 *
 * Returns:
 *
 * Assumptions:
 *
 ****************************************************************************/
static void eliminate_doubles(struct entry *root, struct entry *orig)
{
	if (orig) {
		if (orig->size&&  (orig->path || orig->uncompressed))
			find_identical_file(root, orig);

		eliminate_doubles(root, orig->next);
		eliminate_doubles(root, orig->child);
	}
}

/*****************************************************************************
 *
 * get_page_state
 *
 * Description:
 *    Gets the status of one page.  '0' indicates a compressed page,
 *    otherwise it is an XIP page.
 *
 * Parameters:
 *    (IN) bitmap - XIP bitmap for a file
 *
 *    (IN) offset - offset of the page
 *
 * Returns:
 *    0 - page to be compressed
 *    !0 - page to be XIPed
 *
 * Assumptions:
 *    The offset should be aligned to page size.
 *
 ****************************************************************************/
static int get_page_state(u8 *bitmap, u32 offset)
{
	u32 map_byte;
	u8  map_bit;

	if (!bitmap)
		return 0;
	/* offset is blksize aligned */
	map_byte = (offset / blksize) / 8;
	map_bit = (offset / blksize) % 8;
	return (bitmap[map_byte]&  (1<<  map_bit));
}

/*****************************************************************************
 *
 * set_page_state
 *
 * Description:
 *    Sets up the bitmap for XIP pages.  One bit per page.  '1' indicates
 *    an XIP page, while '0' indicates a compressed page.
 *
 * Parameters:
 *    (OUT) bitmap - XIP bitmap for a file
 *
 *    (IN) offset - offset of the starting XIP page
 *
 *    (IN) size - total size of the XIP data
 *
 * Returns:
 *
 * Assumptions:
 *    The bitmap should be already allocated.
 *
 ****************************************************************************/
static void set_page_state(u8 *bitmap, u32 offset, u32 size)
{
	u32 map_byte;
	u8  map_bit;

	size = size + offset;
	/* align offset */
	offset = offset / blksize * blksize;
	for(; offset < size; offset += blksize) {
		map_byte = (offset / blksize) / 8;
		map_bit = (offset / blksize) % 8;
		bitmap[map_byte] |= (1<<  map_bit);
		/* one more xip node */
		total_xipnodes ++;
	}
}

/*****************************************************************************
 *
 * is_xipfile
 *
 * Description:
 *    Scans the xipfileset[] to see if the file has XIP chunks.  If
 *    it has, the bitmap field of the file entry will be set.
 *
 * Parameters:
 *    (IN) file_entry - pointer to the file entry
 *
 * Returns:
 *    0 - file has no XIP chunks
 *    1 - file has XIP chunks
 *
 * Assumptions:
 *
 ****************************************************************************/
static int is_xipfile(struct entry *file_entry)
{
	u32 i;
	file_entry->bitmap = NULL;

	if ((file_entry->path == NULL)||(xipfileset == NULL) || (xipchunkset == NULL))
		return 0;

	for(i = 0; i<  total_xipfiles; i ++) {
		if (!strcmp(xipfileset[i].path, file_entry->path)) {
			u32 cur = xipfileset[i].index;
			u32 mapsize = file_entry->total_entries;
			u32 chunksize;
			mapsize = (mapsize - 1) / 8 + 1;

			/* allocate bitmap */
			file_entry->bitmap = malloc(sizeof(char) * mapsize);
			if (!file_entry->bitmap)
				die(MKFS_ERROR, 1, "malloc failed");
			if( xip_entire_file )
				memset(file_entry->bitmap, 0xFF, sizeof(char) * mapsize);
			else
				memset(file_entry->bitmap, 0, sizeof(char) * mapsize);

			/* set bitmap */
			for(; cur<  (xipfileset[i].chunknb + xipfileset[i].index); cur ++) {
				if (xipchunkset[cur].offset>= file_entry->size)
					continue;
				chunksize = xipchunkset[cur].size;
				if ((xipchunkset[cur].offset + chunksize)>  file_entry->size)
					chunksize = file_entry->size - xipchunkset[cur].offset;
				set_page_state(file_entry->bitmap, xipchunkset[cur].offset, chunksize);
			}
			/* If the last block is to XIP but its size is less than a page,
			it will be stored un-compressed in byte-aligned region */
			{
				u32 offset = file_entry->size;
				offset = offset / blksize * blksize;
				if ((get_page_state(file_entry->bitmap, offset))&&  (file_entry->size % blksize))
					total_xipnodes --;
			}
			return 1;
		}
	}
	return 0;
}

/*
 * We define our own sorting function instead of using alphasort which
 * uses strcoll and changes ordering based on locale information.
 */
/* The function must be this format
	int (*compar)(const struct dirent **, const struct dirent **))
*/
static int axsort(const struct dirent **a, const struct dirent **b)
{
	return strcmp((*a)->d_name, (*b)->d_name);
}

/*****************************************************************************
 *
 * find_mode_index
 *
 * Description:
 *    finds the mode uid and gid combo in the index of combos or adds it
 *
 * Parameters:
 *    (IN) mode - st_mode of the file to be indexed
 *
 *    (IN) uid - st_uid of the file to be indexed
 *
 *    (IN) gid - st_gid of the file to be indexed
 *
 * Returns:
 *     The index corresponding to the permission bits in the mode_table
 * Assumptions:
 *
 ****************************************************************************/
static u32 find_mode_index(mode_t mode, uid_t uid, gid_t gid)
{
	u32 i = 0;

	if ( mode_index != NULL ) {
		while(mode_index[i]){
			if( (mode_index[i]->mode == (u32) mode)&&  (mode_index[i]->uid == (u32) uid)&&  (mode_index[i]->gid == (u32) gid) ) {
				return i;
			}
			i++;
		}
	}

	mode_index = (struct axfs_mode_bits **) realloc(mode_index, sizeof(struct axfs_mode_bits *)*(i+2));
	mode_index[i] = (struct axfs_mode_bits *) malloc(sizeof(struct axfs_mode_bits));
	mode_index[i+1] = NULL;
	mode_index[i]->mode = (u32) mode;
	mode_index[i]->uid = (u32) uid;
	mode_index[i]->gid = (u32) gid;
	total_modes++;
	return i;
}

/*free mode_index memory*/
static void free_mode_index(void){
	u32 i = 0;
	while(mode_index[i]){
		free(mode_index[i]);
		i++;
	}
	free(mode_index);
}

static void calculate_mode_table(void)
{
	u32 i = 0;
	u32 * modes;
	u32 * uids;
	u32 * gids;
	struct axfs_mode_bits *mode_table;
	int count = 0;

	while(mode_index[i]) {
		i++;
	}
	count = i;
	modes = malloc(count * 4);
	uids = malloc(count * 4);
	gids = malloc(count * 4);

	for(i=0;i<count;i++) {
		mode_table = mode_index[i];
		modes[i] = mode_table->mode;
		uids[i] = mode_table->uid;
		gids[i] = mode_table->gid;
	}

	process_four_byte_table(&modes_rd,modes,count);
	process_four_byte_table(&uids_rd,uids,count);
	process_four_byte_table(&gids_rd,gids,count);

	free(modes);
	free(uids);
	free(gids);
}

/*****************************************************************************
 *
 * parse_directory
 *
 * Description:
 *    Generates directory tree structure.
 *
 * Parameters:
 *    (IN) root_entry - entry pointer to a directory to be parsed
 *
 *    (IN) name - parent path, or root path for the root entry
 *
 *    (OUT) prev - pointer to the child entry pointer
 *
 *    (OUT) fslen_ub - estimated file system size
 *
 * Returns:
 *
 * Assumptions:
 *
 ****************************************************************************/
static unsigned int parse_directory(struct entry *root_entry,
					const char *name, struct entry **prev,
					loff_t *fslen_ub)
{
	struct dirent **dirlist;
	int totalsize = 0, dircount, dirindex;
	char *path, *endpath;
	size_t len = strlen(name);

	/* set up the path */
	path = malloc(len + 1 + MAX_INPUT_NAMELEN + 1);
	if (!path)
		die(MKFS_ERROR, 1, "malloc failed");

	memcpy(path, name, len);
	endpath = path + len;
	if (path[len - 1] != '/') {
		*endpath = '/';
		endpath++;
	}

	/* read in the directory and sort */
	dircount = scandir(name,&dirlist, 0, axsort);

	if (dircount <  0)
		die(MKFS_ERROR, 1, "scandir failed: %s", name);

	root_entry->total_entries = 0;
	/* process directory */
	for (dirindex = 0; dirindex<  dircount; dirindex++) {
		struct dirent *dirent;
		struct entry *entry;
		struct stat st;
		int size;
		size_t namelen;

		dirent = dirlist[dirindex];

		/* Ignore "." and ".." - we won't be adding them to the archive */
		if (dirent->d_name[0] == '.') {
			if (dirent->d_name[1] == '\0') {
				free(dirent);
				continue;
			}
			if (dirent->d_name[1] == '.') {
				if (dirent->d_name[2] == '\0'){
					free(dirent);
					continue;
				}
			}
		}
		namelen = strlen(dirent->d_name);
		if (namelen>  MAX_INPUT_NAMELEN) {
			die(MKFS_ERROR, 0,
				"very long (%u bytes) filename found: %s\n"
				"please increase MAX_INPUT_NAMELEN in mkfs.axfs.c and recompile",
				namelen, dirent->d_name);
		}
		memcpy(endpath, dirent->d_name, namelen + 1);

		if (lstat(path,&st)<  0) {
			printf("warning: lstat() failed on %s\n",path);
			warn_skip = 1;
			free(dirent);
			continue;
		}
		entry = calloc(1, sizeof(struct entry));
		if (!entry) {
			die(MKFS_ERROR, 1, "calloc failed");
		}
		entry->name = strdup(dirent->d_name);
		if (!entry->name) {
			die(MKFS_ERROR, 1, "strdup failed");
		}
		entry->same =0;
		entry->mode_index = find_mode_index(st.st_mode, st.st_uid, st.st_gid);
		entry->size = st.st_size;

		total_inodes ++;
		total_namesize += namelen + 1;
		root_entry->total_entries ++;
		size = namelen + 1;
		*fslen_ub += size;

		if (S_ISDIR(st.st_mode)) {
			entry->size = parse_directory(entry, path,&entry->child, fslen_ub);
		} else if (S_ISREG(st.st_mode)) {
			if (entry->size) {
				if (access(path, R_OK)<  0) {
					printf("warning: access() failed on %s\n",path);
					warn_skip = 1;
					free(dirent);
					continue;
				}
				entry->path = strdup(path);
				if (!entry->path) {
					die(MKFS_ERROR, 1, "strdup failed");
				}
			}
		} else if (S_ISLNK(st.st_mode)) {
			entry->uncompressed = malloc(entry->size);
			entry->mallocd = 1;
			if (!entry->uncompressed) {
				die(MKFS_ERROR, 1, "malloc failed");
			}
			if (readlink(path, entry->uncompressed, entry->size)<  0) {
				printf("warning: readlink() failed on %s\n",path);
				warn_skip = 1;
				free(dirent);
				continue;
			}
		} else if (S_ISFIFO(st.st_mode) || S_ISSOCK(st.st_mode)) {
			/* maybe we should skip sockets */
			entry->size = 0;
		} else if (S_ISCHR(st.st_mode) || S_ISBLK(st.st_mode)) {
			entry->size = st.st_rdev;
		} else {
			die(MKFS_ERROR, 0, "bogus file type: %s", entry->name);
		}

		if (S_ISREG(st.st_mode) || S_ISLNK(st.st_mode)) {
			if (entry->size) {
				int blocks = ((entry->size - 1) / blksize + 1);
				total_nodes += blocks;
				entry->total_entries = blocks;

				/* node info&  data aligned by blksize */
				*fslen_ub += blksize * blocks;

				/* add xip info if necessary */
				is_xipfile(entry);
			}
		}

		/* Link it into the list */
		*prev = entry;
		prev =&entry->next;
		totalsize += size;
		free(dirent);
	}
	free(path);
	free(dirlist);
	/* allocated by scandir() with malloc() */
	return totalsize;
}

/*****************************************************************************
 *
 * write_superblock
 *
 * Description:
 *    Writes super block.
 *
 * Parameters:
 *    (IN) base - base address of the temp image
 *
 * Returns:
 *
 * Assumptions:
 *
 ****************************************************************************/
static void calculate_superblock(struct axfs_region_desc *region)
{
	struct axfs_super_onmedia *super;

	region->virt_addr = malloc(sizeof(*super));
	memset(region->virt_addr,0,sizeof(*super));
	region->size = sizeof(*super);

	super = (struct axfs_super_onmedia *) region->virt_addr;


	super->magic = cpu_to_be32(AXFS_MAGIC);
	super->cblock_size = cpu_to_be32(4096);
	super->files = cpu_to_be64(total_inodes);
	super->size = cpu_to_be64(total_size);
	super->blocks = cpu_to_be64(total_nodes);
	super->mmap_size = cpu_to_be64(total_size);

	super->strings = cpu_to_be64(region->size);
	super->xip = cpu_to_be64(region->size + sizeof(struct axfs_region_desc_onmedia) * 1);
	super->byte_aligned = cpu_to_be64(region->size + sizeof(struct axfs_region_desc_onmedia) * 2);
	super->compressed = cpu_to_be64(region->size + sizeof(struct axfs_region_desc_onmedia) * 3);
	super->node_type = cpu_to_be64(region->size + sizeof(struct axfs_region_desc_onmedia) * 4);
	super->node_index = cpu_to_be64(region->size + sizeof(struct axfs_region_desc_onmedia) * 5);
	super->cnode_offset = cpu_to_be64(region->size + sizeof(struct axfs_region_desc_onmedia) * 6);
	super->cnode_index = cpu_to_be64(region->size + sizeof(struct axfs_region_desc_onmedia) * 7);
	super->banode_offset = cpu_to_be64(region->size + sizeof(struct axfs_region_desc_onmedia) * 8);
	super->cblock_offset = cpu_to_be64(region->size + sizeof(struct axfs_region_desc_onmedia) * 9);
	super->inode_file_size = cpu_to_be64(region->size + sizeof(struct axfs_region_desc_onmedia) * 10);
	super->inode_name_offset = cpu_to_be64(region->size + sizeof(struct axfs_region_desc_onmedia) * 11);
	super->inode_num_entries = cpu_to_be64(region->size + sizeof(struct axfs_region_desc_onmedia) * 12);
	super->inode_mode_index = cpu_to_be64(region->size + sizeof(struct axfs_region_desc_onmedia) * 13);
	super->inode_array_index = cpu_to_be64(region->size + sizeof(struct axfs_region_desc_onmedia) * 14);
	super->modes = cpu_to_be64(region->size + sizeof(struct axfs_region_desc_onmedia) * 15);
	super->uids = cpu_to_be64(region->size + sizeof(struct axfs_region_desc_onmedia) * 16);
	super->gids = cpu_to_be64(region->size + sizeof(struct axfs_region_desc_onmedia) * 17);
	super->version_major = AXFS_VERSION_MAJOR;
	super->version_minor = AXFS_VERSION_MINOR;
	super->version_sub = AXFS_VERSION_SUB;
	super->timestamp = 0;
	super->page_shift = 12;

	memcpy(super->signature, AXFS_SIGNATURE, sizeof(super->signature));

}

int dir_list_add_to_tail(struct dir_list *list, void * data)
{
	struct dir_list_element * new_element;

	new_element = malloc(sizeof(struct dir_list_element));
	if (new_element == NULL)
		return 1;

	new_element->data = (struct entry *)data;
	new_element->next = NULL;

	if (list->head == NULL) {
		list->head = new_element;
		list->last = new_element;
	} else {
		list->last->next = new_element;
		list->last = new_element;
	}
	list->size++;

	return 0;
}

int dir_list_remove_head(struct dir_list *list)
{
	struct dir_list_element * old;
	if (list->head != NULL) {
		list->size--;
		old = list->head;
		list->head = list->head->next;

		free(old);
		if (list->head == NULL) {
			list->last = NULL;
			goto out;
		} else if (list->head->next == NULL) {
			list->last = list->head;
		}
	}
out:
	return 0;
}

void dir_list_init(struct dir_list *list)
{
	list->size = 0;
	list->head = NULL;
	list->last = NULL;
}

/*****************************************************************************
 *
 * write_directory_structure
 *
 * Description:
 *    Writes inode table and inode name table.  We do a width-first printout
 *    of the directory entries, using a stack to remember the directories
 *    we've seen.
 *
 *    All items in a directory are placed in order in the inode space.  the parent
 *    directory inode points (array_offset) to the first inode in directory.
 *    A linked list is used to save off subdirectories that will be processed once
 *    the current directory is finished writing everying in its directory.
 *    Sub directories must be processes in FIFO order since the space for it's
 *    contents are allocated when the directories inode is written.
 *
 * Parameters:
 *    (IN) entry - pointer to a dir/file entry
 *
 *    (IN) base - base address of the temp image
 *
 * Returns:
 *
 * Assumptions:
 *
 ****************************************************************************/
static void calculate_directory_structure(struct entry *entry)
{
	u32 *inode_file_sizes = NULL;
	u32 *inode_name_offsets = NULL;
	u32 *inode_mode_indexes = NULL;
	u32 *inode_num_entries = NULL;
	u32 *inode_array_indexes = NULL;
	u32 next_node = 0;
	u32 next_inode = 1; /* next available inode, inode 0 is for root */
	int stack_entries = 0;
	int stack_size = 64;
	struct entry **entry_stack;
	struct dir_list dir_list;

	dir_list_init(&dir_list);

	for (;;) {
		while (entry) {
			size_t len = strlen(entry->name) + 1;
			inode_file_sizes = realloc(inode_file_sizes,(entry_count+2)*sizeof(*inode_file_sizes));
			inode_name_offsets = realloc(inode_name_offsets,(entry_count+2)*sizeof(*inode_name_offsets));
			inode_mode_indexes = realloc(inode_mode_indexes,(entry_count+2)*sizeof(*inode_mode_indexes));
			inode_num_entries = realloc(inode_num_entries,(entry_count+2)*sizeof(*inode_num_entries));
			inode_array_indexes = realloc(inode_array_indexes,(entry_count+2)*sizeof(*inode_array_indexes));
			inode_file_sizes[entry_count] = entry->size;
			inode_num_entries[entry_count] = entry->total_entries;
			inode_mode_indexes[entry_count] = entry->mode_index;
			inode_name_offsets[entry_count] = strings_rd.size;
			strings_rd.virt_addr = realloc(strings_rd.virt_addr,strings_rd.size + len + 1);
			memcpy(strings_rd.virt_addr + strings_rd.size, entry->name, len);

			entry_table = realloc(entry_table, (entry_count+2)*sizeof(*entry_table));
			entry_table[entry_count] = entry;

			strings_rd.size += len;

			if (entry->child) {
				/* this is a directory */
				/* we will setup the space for its directory elelemnts and attach
				it to the directory list to be parsed later*/
				dir_list_add_to_tail(&dir_list, entry);
				inode_array_indexes[entry_count] = next_inode;
				next_inode += entry->total_entries;
			} else {
				/* determine if this file is duplicate of another file,
				if so use the origial files nodes */
				if (entry->same != 0 ) {
					if (entry->same->array_offset_set == 1) {
						inode_array_indexes[entry_count] = entry->same->array_offset;
						entry->array_offset = inode_array_indexes[entry_count];
					} else {
						/* because of the search algorithm of the eliminate doubles routine we can
							be trying to process a duplicate before the "orignal" has been written
							as a result we will need to switch things around
						*/
						inode_array_indexes[entry_count] = next_node;
						entry->array_offset = inode_array_indexes[entry_count];
						next_node += entry->total_entries;

						/* now set it up for the "master" duplicate that will be processed later*/
						entry->same->array_offset = entry->array_offset;
						entry->same->array_offset_set =1;
					}
					inode_array_indexes[entry_count] = entry->same->array_offset;
					entry->array_offset = inode_array_indexes[entry_count];
				} else {
					/* this check is again to help fix the hack around the elinimate
						doubles parsing issue. if a double was processed ealier as seen
						above in the else condition we don't want to process it again and set
						a new node chain*/
					if (entry->array_offset_set != 1) {
						inode_array_indexes[entry_count] = next_node;
						entry->array_offset = inode_array_indexes[entry_count];
						next_node += entry->total_entries;
					} else {
						/* this one is the "master" for doubles and one of its doubles
						has been processed already, there for we just need to set the
						node information for this inode */
						inode_array_indexes[entry_count] = entry->array_offset;
					}
				}
				entry->array_offset_set =1;
			}
			entry_count++;
			entry = entry->next;
		}


		/* Parse through all of the saved sub directories found in the entries.
		* When the list of sub driectories is empty then are done and need to exit
		*  the for loop */
		if (( dir_list.size == 0 ) )
			break;

		/* get the next entries child from the list and then remove it from the list */
		entry = dir_list.head->data->child;
		dir_list_remove_head(&dir_list);
	}

	process_four_byte_table(&inode_file_size_rd,inode_file_sizes,entry_count);
	process_four_byte_table(&inode_name_offset_rd,inode_name_offsets,entry_count);
	process_four_byte_table(&inode_mode_index_rd,inode_mode_indexes,entry_count);
	process_four_byte_table(&inode_num_entries_rd,inode_num_entries,entry_count);
	process_four_byte_table(&inode_array_index_rd,inode_array_indexes,entry_count);
	free(inode_file_sizes);
	free(inode_name_offsets);
	free(inode_mode_indexes);
	free(inode_num_entries);
	free(inode_array_indexes);

	return;
}

static void log_xipnode(u8 **node_type, u32 **node_index, u32 *node_count)
{
	*node_count += 1;
	*node_type = realloc(*node_type,(*node_count)*sizeof(**node_type));
	*node_index = realloc(*node_index,(*node_count)*sizeof(**node_index));

	(*node_type)[*node_count-1] = XIP;
	(*node_index)[*node_count-1] = xip_rd.size/blksize;
}

static void log_cnode(u8 **node_type, u32 **node_index, u32 *node_count, u32 **cnode_offset,
			u32 **cnode_index, u32 *cnode_count,u32 **cblock_offset, u32 *cblock_count)
{
	*node_count += 1;
	*node_type = realloc(*node_type,(*node_count)*sizeof(**node_type));
	*node_index = realloc(*node_index,(*node_count)*sizeof(**node_index));

	(*node_type)[*node_count-1] = Compressed;
	(*node_index)[*node_count-1] = *cnode_count;

	*cnode_count += 1;
	*cnode_offset = realloc(*cnode_offset,(*cnode_count)*sizeof(**cnode_offset));
	*cnode_index = realloc(*cnode_index,(*cnode_count)*sizeof(**cnode_index));

	(*cnode_offset)[*cnode_count-1] = 0;
	(*cnode_index)[*cnode_count-1] = *cblock_count;

	*cblock_count += 1;
	*cblock_offset = realloc(*cblock_offset,(*cblock_count)*sizeof(**cblock_offset));

	(*cblock_offset)[*cblock_count-1] = compressed_rd.size;
}

static void log_banode(u8 **node_type, u32 **node_index, u32 *node_count, u32 **banode_offset,
			u32 *banode_count)
{
	*node_count += 1;
	*node_type = realloc(*node_type,(*node_count)*sizeof(**node_type));
	*node_index = realloc(*node_index,(*node_count)*sizeof(**node_index));

	(*node_type)[*node_count-1] = Byte_Aligned;
	(*node_index)[*node_count-1] = *banode_count;

	*banode_count += 1;
	*banode_offset = realloc(*banode_offset,(*banode_count)*sizeof(**banode_offset));

	(*banode_offset)[*banode_count-1] = byte_aligned_rd.size;
}

/*****************************************************************************
 *
 * do_compress
 *
 * Description:
 *    Writes data for one file page by page, according to the XIP bitmap.
 *    An XIP block, which size is less than one page, will be stored
 *    uncompressed in byte-aligned data section.  If size of a compressed
 *    page is larger than its original size, it will be stored uncompressed
 *    in byte-aligned data section.  This function also writes the node table.
 *
 * Parameters:
 *    (IN) entry - pointer to a dir/file entry
 *
 *    (IN) base - base address of the temp image
 *
 * Returns:
 *
 * Assumptions:
 *
 ****************************************************************************/
static void do_compress(struct entry *entry, u8 **node_type, u32 **node_index, u32 *node_count,
			u32 **cnode_offset, u32 **cnode_index, u32 *cnode_count,
			u32 **banode_offset, u32 *banode_count, u32 **cblock_offset,
			u32 *cblock_count)
{
	void *file_data = entry->uncompressed;
	u32 bytes_to_write = entry->size;
	u32 new_size = 0;
	u32 offset = 0;
	int change;
	int force_xip = 0;
	int fd;
	u8 buffer[4];
	u8 elf_magic[4] = {0x7F,'E','L','F'};

	if(file_data == NULL)
		return;

	/* If the file is an executable ELF file, force to try to XIP the page */
	force_xip = 0;
	if( xip_all_files )
	{
		/* Check 'x' bit of Owner field ---x------ */
		if( mode_index[entry->mode_index]->mode & 0x40 )
		{
			/* Check for ELF magic number */
			fd = -1;
			if (entry->path)	/* symlink nodes don't have paths */
				fd = open(entry->path, O_RDONLY );
			if( fd != -1)
			{
				buffer[0] = 0; /* in case file is empty */
				read(fd,buffer,4);
				if( *(u32 *)buffer == *(u32 *)elf_magic)
					force_xip = 1;
			}
		}
	}

#ifdef DEBUG
	/* This prints out all the executable files it did find */
	if( force_xip )
		printf("name=%s, mode = 0x%X  (%d%d%d)\n", entry->name, mode_index[entry->mode_index]->mode,
			((mode_index[entry->mode_index]->mode) >> 6) & 7,
			((mode_index[entry->mode_index]->mode) >> 3) & 7,
			((mode_index[entry->mode_index]->mode) >> 0) & 7 );
#endif

	do {
		unsigned long len = 2 * blksize;
		unsigned int input = bytes_to_write;
		int err;

		if (input>  blksize)
			input = blksize;

		bytes_to_write -= input;
		if (!force_xip && !get_page_state(entry->bitmap, offset)) {
			/* Not XIP page */
			compressed_rd.virt_addr = realloc(compressed_rd.virt_addr,compressed_rd.size + 2*blksize);
			err = compress2(compressed_rd.virt_addr + compressed_rd.size,&len, file_data, input, Z_BEST_COMPRESSION);
			if (err != Z_OK)
				die(MKFS_ERROR, 0, "compression error: %s", zError(err));

			if (len>= input) {
				/* If it doesn't compress, don't compress it */
				byte_aligned_rd.virt_addr = realloc(byte_aligned_rd.virt_addr,byte_aligned_rd.size + blksize + blksize);
				memset(byte_aligned_rd.virt_addr + byte_aligned_rd.size,0,2*blksize);
				/* store it un-compressed */
				memcpy(byte_aligned_rd.virt_addr + byte_aligned_rd.size, file_data, input);
				len = input + 1;
				log_banode(node_type,node_index,node_count,banode_offset,
					banode_count);
				byte_aligned_rd.size += len;
			} else {
				log_cnode(node_type,node_index,node_count,cnode_offset,
					cnode_index,cnode_count,cblock_offset,cblock_count);
				compressed_rd.size += len;
			}

			new_size += len;

		} else if (input == blksize) {
			/* It's a full XIP page */
			xip_rd.virt_addr = realloc(xip_rd.virt_addr,xip_rd.size + blksize);
			/* store it uncompressed in XIP data region */
			memcpy(xip_rd.virt_addr + xip_rd.size, file_data, input);
			new_size += input;
			log_xipnode(node_type,node_index,node_count);
			xip_rd.size += input;
		} else {
			/* It was supposed to be XIP but because it's a not a full page store in ba region */
			byte_aligned_rd.virt_addr = realloc(byte_aligned_rd.virt_addr,byte_aligned_rd.size + blksize);
			/* store it uncompressed in byte-aligned data region */
			memcpy(byte_aligned_rd.virt_addr + byte_aligned_rd.size, file_data, input);
			new_size += input;
			log_banode(node_type,node_index,node_count,banode_offset,banode_count);
			byte_aligned_rd.size += input;
		}
		file_data += input;
		offset += input;
	} while (bytes_to_write);

	change = new_size - entry->size;
	if (silent == 0) {
		printf("%6.2f%% (%+d bytes)\t%s\n",
			(change * 100) / (double) entry->size, change, entry->name);
	}
	return;
}

static void do_calculate_data(u8 **node_type, u32 **node_index,
			u32 *node_count, u32 **cnode_offset, u32 **cnode_index, u32 *cnode_count,
			u32 **banode_offset, u32 *banode_count, u32 **cblock_offset,
			u32 *cblock_count)
{
	int i;
	struct entry *entry;

	for(i=0; i<entry_count; i++) {
		entry = entry_table[i];
		if (!entry->same) {
			map_entry(entry);
			do_compress(entry,node_type,node_index,node_count,cnode_offset,
					cnode_index,cnode_count,banode_offset,banode_count,
					cblock_offset,cblock_count);
			unmap_entry(entry);
		}
	}
}

/*****************************************************************************
 *
 * calculate_data
 *
 * Description:
 *    Traverses the entry tree, writing data for every item that has
 *    non-null entry->path (i.e. every non-empty regfile) and non-null
 *    entry->uncompressed (i.e. every symlink).
 *
 * Parameters:
 *    (IN) entry - pointer to a dir/file entry
 *
 *    (IN) base - base address of the temp image
 *
 * Returns:
 *
 * Assumptions:
 *
 ****************************************************************************/
static void calculate_data(void)
{
	u8 **node_type;
	u32 **node_index;
	u32 **cnode_offset;
	u32 **cnode_index;
	u32 **banode_offset;
	u32 **cblock_offset;

	u32 node_count = 0;
	u32 cnode_count = 0;
	u32 cblock_count = 0;
	u32 banode_count = 0;


	node_type = malloc(sizeof(*node_type));
	node_index = malloc(sizeof(*node_index));
	cnode_offset = malloc(sizeof(*cnode_offset));
	cnode_index = malloc(sizeof(*cnode_index));
	banode_offset = malloc(sizeof(*banode_offset));
	cblock_offset = malloc(sizeof(*cblock_offset));

	*node_type = NULL;
	*node_index = NULL;
	*cnode_offset = NULL;
	*cnode_index = NULL;
	*banode_offset = NULL;
	*cblock_offset = NULL;


	do_calculate_data(node_type,node_index,&node_count,
		cnode_offset,cnode_index,&cnode_count,banode_offset,
		&banode_count,cblock_offset,&cblock_count);

	log_banode(node_type,node_index,&node_count,banode_offset,
		&banode_count);
	log_cnode(node_type,node_index,&node_count,cnode_offset,
			cnode_index,&cnode_count,cblock_offset,&cblock_count);
	log_xipnode(node_type,node_index,&node_count);

	process_one_byte_table(&node_type_rd,*node_type,node_count);
	process_four_byte_table(&node_index_rd,*node_index,node_count);
	process_four_byte_table(&cnode_offset_rd,*cnode_offset,cnode_count);
	process_four_byte_table(&cnode_index_rd,*cnode_index,cnode_count);
	process_four_byte_table(&banode_offset_rd,*banode_offset,banode_count);
	process_four_byte_table(&cblock_offset_rd,*cblock_offset,cblock_count);

	free(*node_type);
	free(*node_index);
	free(*cnode_offset);
	free(*cnode_index);
	free(*banode_offset);
	free(*cblock_offset);

	free(node_type);
	free(node_index);
	free(cnode_offset);
	free(cnode_index);
	free(banode_offset);
	free(cblock_offset);
}

static u32 calculate_image(void)
{
	u32 size = 0;

	size += sizeof(struct axfs_super_onmedia);
	size += sizeof(struct axfs_region_desc_onmedia)*18;
	node_type_rd.fsoffset = size;
	size += node_type_rd.size;
	node_index_rd.fsoffset = size;
	size += node_index_rd.size;
	cnode_offset_rd.fsoffset = size;
	size += cnode_offset_rd.size;
	cnode_index_rd.fsoffset = size;
	size += cnode_index_rd.size;
	banode_offset_rd.fsoffset = size;
	size += banode_offset_rd.size;
	cblock_offset_rd.fsoffset = size;
	size += cblock_offset_rd.size;
	inode_file_size_rd.fsoffset = size;
	size += inode_file_size_rd.size;
	inode_name_offset_rd.fsoffset = size;
	size += inode_name_offset_rd.size;
	inode_num_entries_rd.fsoffset = size;
	size += inode_num_entries_rd.size;
	inode_mode_index_rd.fsoffset = size;
	size += inode_mode_index_rd.size;
	inode_array_index_rd.fsoffset = size;
	size += inode_array_index_rd.size;
	modes_rd.fsoffset = size;
	size += modes_rd.size;
	uids_rd.fsoffset = size;
	size += uids_rd.size;
	gids_rd.fsoffset = size;
	size += gids_rd.size;
	xippadding_rd.fsoffset = size;
	xippadding_rd.size = ((size - 1) | (blksize - 1)) + 1 - size;
	size += xippadding_rd.size;
	xip_rd.fsoffset = size;
	size += xip_rd.size;
	byte_aligned_rd.fsoffset = size;
	size += byte_aligned_rd.size;
	compressed_rd.fsoffset = size;
	size += compressed_rd.size;
	strings_rd.fsoffset = size;
	size += strings_rd.size;
	endpadding_rd.fsoffset = size;
	endpadding_rd.size = ((size - 1) | (blksize - 1)) + 1 - size;
	size += sizeof(AXFS_MAGIC);//endpadding_rd.size;

	return size;
}

static void print_stats(void)
{
	printf("\n");
	printf("number of files:                   %lu\n",(unsigned long int)total_inodes);
	printf("number of %iKB nodes:               %lu\n",blksize/1024,(unsigned long int)total_nodes);

	/* BUG: Need to change the way total_xipnodes is counted (or reported) when not reading
	        every single PAGE to XIP from an input file */
	if( !xip_all_files && !xip_entire_file )
	{
		printf("number of %iKB xip nodes:           %lu\n",blksize/1024,(unsigned long int)total_xipnodes);
		printf("number of xip files:               %lu\n",(unsigned long int)total_xipfiles);
	}
}

static void print_offsets(u32 size)
{
	printf("\n");
	if ( silent == 0 ) {
		printf("offset to node_type bytetable:          %llu\n", node_type_rd.fsoffset);
		printf("offset to node_index bytetable:	        %llu\n", node_index_rd.fsoffset);
		printf("offset to cnode_offset bytetable:       %llu\n", cnode_offset_rd.fsoffset);
		printf("offset to cnode_index bytetable:        %llu\n", cnode_index_rd.fsoffset);
		printf("offset to banode_offset bytetable:      %llu\n", banode_offset_rd.fsoffset);
		printf("offset to cblock_offset bytetable:      %llu\n", cblock_offset_rd.fsoffset);
		printf("offset to inode_file_size bytetable:    %llu\n", inode_file_size_rd.fsoffset);
		printf("offset to inode_name_offset bytetable:  %llu\n", inode_name_offset_rd.fsoffset);
		printf("offset to inode_num_entries bytetable:  %llu\n", inode_num_entries_rd.fsoffset);
		printf("offset to inode_mode_index bytetable:   %llu\n", inode_mode_index_rd.fsoffset);
		printf("offset to inode_array_index bytetable:  %llu\n", inode_array_index_rd.fsoffset);
		printf("offset to modes bytetable:              %llu\n", modes_rd.fsoffset);
		printf("offset to uids bytetable:               %llu\n", uids_rd.fsoffset);
		printf("offset to gids bytetable:               %llu\n", gids_rd.fsoffset);
		printf("offset to zero padding:                 %llu\n", xippadding_rd.fsoffset);
		printf("offset to xip data:                     %llu\n", xip_rd.fsoffset);
		printf("offset to byte_aligned data:            %llu\n", byte_aligned_rd.fsoffset);
		printf("offset to compressed data:              %llu\n", compressed_rd.fsoffset);
		printf("offset to strings data:                 %llu\n", strings_rd.fsoffset);
		printf("offset to zero padding:                 %llu\n", endpadding_rd.fsoffset);
		printf("\n");
	}
	printf("Total image size:                       %lu\n", (long unsigned int)size);
}

static void print_superblock(void)
{
	struct axfs_super_onmedia *sbo;

	sbo = (struct axfs_super_onmedia *)super_rd.virt_addr;

#if 0
	/* for debuging superblocks */
	printf("\naxfs: strings_rd			%llu\n",be64_to_cpu(sbo->strings));
	printf("axfs: xip_rd				%llu\n",be64_to_cpu(sbo->xip));
	printf("axfs: compressed_rd			%llu\n",be64_to_cpu(sbo->compressed));
	printf("axfs: byte_aligned_rd		%llu\n",be64_to_cpu(sbo->byte_aligned));
	printf("axfs: node_type_rd			%llu\n",be64_to_cpu(sbo->node_type));
	printf("axfs: node_index_rd			%llu\n",be64_to_cpu(sbo->node_index));
	printf("axfs: cnode_offset_rd		%llu\n",be64_to_cpu(sbo->cnode_offset));
	printf("axfs: cnode_index_rd		%llu\n",be64_to_cpu(sbo->cnode_index));
	printf("axfs: banode_offset_rd		%llu\n",be64_to_cpu(sbo->banode_offset));
	printf("axfs: cblock_offset_rd		%llu\n",be64_to_cpu(sbo->cblock_offset));
	printf("axfs: inode_file_size_rd		%llu\n",be64_to_cpu(sbo->inode_file_size));
	printf("axfs: inode_name_offset_rd		%llu\n",be64_to_cpu(sbo->inode_name_offset));
	printf("axfs: inode_num_entries_rd		%llu\n",be64_to_cpu(sbo->inode_num_entries));
	printf("axfs: inode_mode_index_rd		%llu\n",be64_to_cpu(sbo->inode_mode_index));
	printf("axfs: inode_array_index_rd		%llu\n",be64_to_cpu(sbo->inode_array_index));
	printf("axfs: modes_rd			%llu\n",be64_to_cpu(sbo->modes));
	printf("axfs: uids_rd			%llu\n",be64_to_cpu(sbo->uids));
	printf("axfs: gids_rd			%llu\n\n",be64_to_cpu(sbo->gids));
#endif
}

static void write_region_data(int fd, struct axfs_region_desc * region)
{
	ssize_t written = 0;

	if((region->size != 0)&&(region->virt_addr != NULL))
		written = write(fd,region->virt_addr,region->size);
	if(written != region->size)
		die(MKFS_ERROR, 0, "region data write failed\n");
}

static void write_region_descriptor(int fd, struct axfs_region_desc * region)
{
	struct axfs_region_desc_onmedia *onmedia;
	ssize_t written;

	onmedia = malloc(sizeof(*onmedia));
	memset(onmedia,0,sizeof(*onmedia));
	onmedia->fsoffset = cpu_to_be64(region->fsoffset);
	onmedia->size = cpu_to_be64(region->size);
	onmedia->compressed_size = cpu_to_be64(region->compressed_size);
	onmedia->max_index = cpu_to_be64(region->max_index);
	onmedia->table_byte_depth = region->table_byte_depth;
	onmedia->incore = region->incore;

	written = write(fd,onmedia,sizeof(*onmedia));
	free(onmedia);
	if(written != sizeof(*onmedia))
		die(MKFS_ERROR, 0, "region descriptor write failed\n");
}

static void write_region_descriptors(int fd)
{
	write_region_descriptor(fd,&strings_rd);
	write_region_descriptor(fd,&xip_rd);
	write_region_descriptor(fd,&byte_aligned_rd);
	write_region_descriptor(fd,&compressed_rd);
	write_region_descriptor(fd,&node_type_rd);
	write_region_descriptor(fd,&node_index_rd);
	write_region_descriptor(fd,&cnode_offset_rd);
	write_region_descriptor(fd,&cnode_index_rd);
	write_region_descriptor(fd,&banode_offset_rd);
	write_region_descriptor(fd,&cblock_offset_rd);
	write_region_descriptor(fd,&inode_file_size_rd);
	write_region_descriptor(fd,&inode_name_offset_rd);
	write_region_descriptor(fd,&inode_num_entries_rd);
	write_region_descriptor(fd,&inode_mode_index_rd);
	write_region_descriptor(fd,&inode_array_index_rd);
	write_region_descriptor(fd,&modes_rd);
	write_region_descriptor(fd,&uids_rd);
	write_region_descriptor(fd,&gids_rd);
}

static void write_image(int fd)
{
	write_region_data(fd,&super_rd);
	write_region_descriptors(fd);
	write_region_data(fd,&node_type_rd);
	write_region_data(fd,&node_index_rd);
	write_region_data(fd,&cnode_offset_rd);
	write_region_data(fd,&cnode_index_rd);
	write_region_data(fd,&banode_offset_rd);
	write_region_data(fd,&cblock_offset_rd);
	write_region_data(fd,&inode_file_size_rd);
	write_region_data(fd,&inode_name_offset_rd);
	write_region_data(fd,&inode_num_entries_rd);
	write_region_data(fd,&inode_mode_index_rd);
	write_region_data(fd,&inode_array_index_rd);
	write_region_data(fd,&modes_rd);
	write_region_data(fd,&uids_rd);
	write_region_data(fd,&gids_rd);
	write_region_data(fd,&xippadding_rd);
	write_region_data(fd,&xip_rd);
	write_region_data(fd,&byte_aligned_rd);
	write_region_data(fd,&compressed_rd);
	write_region_data(fd,&strings_rd);
	write_region_data(fd,&endpadding_rd);
}

static void free_region(struct axfs_region_desc * region)
{
	if(region->virt_addr != NULL){
		free(region->virt_addr);
	}
}

static void free_regions(void)
{
	free_region(&strings_rd);
	free_region(&xip_rd);
	free_region(&byte_aligned_rd);
	free_region(&compressed_rd);
	free_region(&node_type_rd);
	free_region(&node_index_rd);
	free_region(&cnode_offset_rd);
	free_region(&cnode_index_rd);
	free_region(&banode_offset_rd);
	free_region(&cblock_offset_rd);
	free_region(&inode_file_size_rd);
	free_region(&inode_name_offset_rd);
	free_region(&inode_num_entries_rd);
	free_region(&inode_mode_index_rd);
	free_region(&inode_array_index_rd);
	free_region(&modes_rd);
	free_region(&uids_rd);
	free_region(&gids_rd);
	free_region(&super_rd);
	free_region(&endpadding_rd);
	free_region(&xippadding_rd);
}

static void free_fileentries(struct entry *entry)
{
	struct entry *next;

	if(entry->bitmap != NULL)
		free(entry->bitmap);
	if(entry->mallocd == 1)
		free(entry->uncompressed);
	if(entry->child)
		free_fileentries(entry->child);
	next = entry->next;
	if(entry->name != NULL)
		free(entry->name);
	if(entry->path != NULL)
		free(entry->path);
	if(next != NULL)
		free_fileentries(next);
	free(entry);
}

static void init_region(struct axfs_region_desc * region)
{
	region->fsoffset = 0;
	region->size = 0;
	region->compressed_size = 0;
	region->max_index = 0;
	region->virt_addr = NULL;
	region->table_byte_depth = 0;
	region->incore = 0;
}

static void init_regions(void)
{
	init_region(&strings_rd);
	init_region(&xip_rd);
	init_region(&byte_aligned_rd);
	init_region(&compressed_rd);
	init_region(&node_type_rd);
	init_region(&node_index_rd);
	init_region(&cnode_offset_rd);
	init_region(&cnode_index_rd);
	init_region(&banode_offset_rd);
	init_region(&cblock_offset_rd);
	init_region(&inode_file_size_rd);
	init_region(&inode_name_offset_rd);
	init_region(&inode_num_entries_rd);
	init_region(&inode_mode_index_rd);
	init_region(&inode_array_index_rd);
	init_region(&modes_rd);
	init_region(&uids_rd);
	init_region(&gids_rd);
	init_region(&super_rd);
	init_region(&endpadding_rd);
	init_region(&xippadding_rd);
}

static void free_xipfileset(void)
{
	int i;
	xipfilePtr x;
	for(i=0;i<total_xipfiles;i++){
		x =&(xipfileset[i]);
		free(x->path);
	}
}

int main(int argc, char **argv)
{
	struct stat st; /* for lstat, stat */
	struct entry *root_entry;
	struct entry *entry;
	char const *infile = NULL;
	char const *dirname, *outfile;
	char const *inode_file = NULL;
	char *buf;
	/* initial guess (upper-bound) of required filesystem size */
	loff_t fslen_ub = sizeof(struct axfs_super_onmedia);
	ssize_t written;
	u32 *magic_nb;
	int fd;
	FILE *finode;
	int c; /* for getopt */
	int dirlen;
	int i;

	if (argc)
		progname = argv[0];

	/* command line options */
	while ((c = getopt(argc, argv, "hi:n:sae")) != EOF) {
		switch (c) {
		case 'h':
			usage(MKFS_OK);
			break;
		case 'i':
			infile = optarg;
			if (lstat(infile,&st)<  0)
				die(MKFS_ERROR, 1, "lstat failed: %s", infile);
			break;
		case 'n':
			inode_file = optarg;
			break;
		case 's':
			silent = 1;
			break;
		case 'a':
			xip_all_files = 1;
			break;
		case 'e':
			xip_entire_file = 1;
			break;
		}
	}

	if ((argc - optind) != 2)
		usage(MKFS_USAGE);
	dirname = argv[optind];
	outfile = argv[optind + 1];

	if (stat(dirname,&st)<  0)
		die(MKFS_USAGE, 1, "stat failed: %s", dirname);

	dirlen = strlen(dirname);
	if (!(dirname[dirlen-1] == '/')) {
		buf = (char *)dirname;
		dirname = (char *) malloc(dirlen+1);
		sprintf((char*)dirname,"%s/",buf);
	}


	/* ignore the input file if fail to parse */
	if(infile != NULL)
		parseInfile((char *)infile, (char *)dirname);

	fd = open(outfile, O_WRONLY | O_CREAT | O_TRUNC, 0666);
	if (fd<  0)
		die(MKFS_USAGE, 1, "open failed: %s", outfile);

	/* pre-count the root */
	total_inodes = 1;
	total_nodes = 0;
	total_namesize = strlen(dirname) + 1;
	total_xipnodes = 0;

	root_entry = calloc(1, sizeof(struct entry));
	if (!root_entry)
		die(MKFS_ERROR, 1, "calloc failed");

	root_entry->mode_index = find_mode_index(st.st_mode, st.st_uid, st.st_gid);
	root_entry->name = strdup("./");
	if (!root_entry->name)
		die(MKFS_ERROR, 1, "strdup failed");

	root_entry->size = parse_directory(root_entry, dirname,
		&root_entry->child,&fslen_ub);

	free(xipchunkset);
	free_xipfileset();
	free(xipfileset);
	xipchunkset = NULL;
	xipfileset = NULL;

	init_regions();

	/* find duplicate files. TODO: uses the most inefficient algorithm
		possible. */
	eliminate_doubles(root_entry, root_entry);

	calculate_mode_table();
	calculate_directory_structure(root_entry);
	calculate_data();
	total_size = calculate_image();
	calculate_superblock(&super_rd);

	print_superblock();
	print_stats();
	print_offsets(total_size);

	/* populate padding for XIP region and for end of image */
	xippadding_rd.virt_addr = malloc(xippadding_rd.size);
	memset(xippadding_rd.virt_addr,0,xippadding_rd.size);
	endpadding_rd.virt_addr = malloc(endpadding_rd.size);
	memset(endpadding_rd.virt_addr,0,endpadding_rd.size);
	*((int*)endpadding_rd.virt_addr) = cpu_to_be32(AXFS_MAGIC);

	write_image(fd);

	close(fd);

	if( inode_file ) {
		finode = fopen(inode_file, "w");
		if ( finode == NULL )
			die(MKFS_USAGE, 1, "open failed: %s", inode_file);
		fprintf(finode,"inode,type,filename,pages\n");
		for( i=0; i < entry_count; i++) {
			entry = entry_table[i];
			fprintf(finode,"%04d,",	i);
			switch (entry->mode_index) {
				case 0: fprintf(finode,"dir,");
					break;
				case 1: fprintf(finode,"sym,");
					break;
				case 2: fprintf(finode,"fil,");
					break;
			}
			fprintf(finode,"%s,%d\n",entry->name,entry->total_entries);
		}
		fclose(finode);
	}

	free_mode_index();
	free_regions();
	free_fileentries(root_entry);

	/* (These warnings used to come at the start, but they scroll off the
	   screen too quickly.) */
	if (warn_skip)
		fprintf(stderr, "warning: files were skipped due to errors\n");

	exit(MKFS_OK);
}

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
 * axfs_profiling.c -
 *   Tracks pages of files that enter the page cache.  Outputs through a proc
 *   file which generates a comma separated data file with path, page offset,
 *   count of times entered page cache.
 */
#include "axfs.h"

#ifdef CONFIG_AXFS_PROFILING
#include <linux/module.h>
#include <linux/vmalloc.h>
#include <linux/proc_fs.h>
#if LINUX_VERSION_CODE > KERNEL_VERSION(3,9,0)
#include <asm/uaccess.h>
#endif

#define AXFS_PROC_DIR_NAME "axfs"

#define MAX_STRING_LEN 1024
#define TEMP_BUFFER_SIZE 4096

struct axfs_profiling_data {
	u64 inode_number;
	unsigned long count;
};

struct axfs_profiling_manager {
	struct axfs_profiling_data *profiling_data;
	struct axfs_super *sbi;
	u32 *dir_structure;
	u32 size;
	u32 count;
	char *temp;
};

/* Handles for our Directory and File */
static struct proc_dir_entry *axfs_proc_dir;
static u32 proc_name_inc;

/******************************************************************************
 *
 * axfs_init_profile_dir_structure
 *
 * Description:
 *   Creates the structures for tracking the page usage data and creates the
 *   proc file that will be used to get the data.
 *
 * Parameters:
 *    (IN) manager - pointer to the profile manager for the filing system
 *
 *    (IN) num_inodes - number of files in the system
 *
 * Returns:
 *    0
 *
 *****************************************************************************/
static int axfs_init_profile_dir_structure(struct axfs_profiling_manager
					   *manager, u32 num_inodes)
{

	struct axfs_super *sbi = (struct axfs_super *)manager->sbi;
	u32 child_index = 0, i, j;
	u32 *dir_structure = manager->dir_structure;

	/* loop through each inode in the image and find all
	   of the directories and mark their children */
	for (i = 0; i < num_inodes; i++) {
		/* determine if the entry is a directory */
		if (!S_ISDIR(axfs_get_mode(sbi, i)))
			continue;

		/* get the index number for this directory */
		child_index = axfs_get_inode_array_index(sbi, i);

		/* get the offset to its children */
		for (j = 0; j < axfs_get_inode_num_entries(sbi, i); j++) {
			if (dir_structure[child_index + j] != 0) {
				printk(KERN_ERR
				       "axfs: ERROR inode was already set old "
				       "%lu new %lu\n", (unsigned long)
				       dir_structure[child_index + j],
				       (unsigned long)i);
			}
			dir_structure[child_index + j] = i;
		}
	}

	return 0;
}

/******************************************************************************
 *
 * axfs_get_directory_path
 *
 * Description:
 *   Determines the directory path of every file for printing the spreadsheet.
 *
 * Parameters:
 *    (IN) manager - Pointer to axfs profile manager
 *
 *    (OUT) buffer - Pointer to the printable directory path for each file
 *
 *    (IN) inode_number - Inode number of file to look up
 *
 * Returns:
 *    Size of the path to the file
 *
 *
 **************************************************************************/
static char * axfs_get_directory_path(struct axfs_profiling_manager *manager,
				      u32 *count, u32 inode_number)
{
	u32 path_depth = 0;
	u32 string_len = 0;
	u32 index = inode_number;
	u32 dir_number;
	char **path_array = NULL;
	struct axfs_super *sbi = (struct axfs_super *)manager->sbi;
	int i;
	char *buffer;
	char *temp;

	/* determine how deep the directory path is and how big the name
	   string will be walk back until the root directory index is found
	   (index 0 is root) */
	while (manager->dir_structure[index] != 0) {
		path_depth++;
		/* set the index to the index of the parent directory */
		index = manager->dir_structure[index];
	}

	if (path_depth != 0) {
		/* create an array that will hold a pointer for each of the
		   directories names */
		path_array = vmalloc(path_depth * sizeof(*path_array));
		if (path_array == NULL) {
			printk(KERN_DEBUG
			       "axfs: directory_path vmalloc failed.\n");
			return NULL;
		}
	}

	index = manager->dir_structure[inode_number];
	for (i = path_depth; i > 0; i--) {
		/* get the array_index for the directory corresponding to
		   index */
		dir_number = axfs_get_inode_array_index(sbi, index);

		/* store a pointer to the name in the array */
		path_array[(i - 1)] = axfs_get_inode_name(sbi, index);
		index = manager->dir_structure[index];

		/* add up the individual string lengths in the path */
		*count += strlen(path_array[(i - 1)]);

		/* account for the trailing '/' */
		*count += 1;
	}

	/* account for leading './' */
	*count += 2;

	/* malloc the buffer that will hold the directory string
	   don't forget the trailing NULL*/
	buffer = vmalloc(*count + 1);
	if (buffer == NULL) {
		printk(KERN_DEBUG
		       "axfs: directory buffer vmalloc failed.\n");
		return NULL;
	}
	buffer[*count] = 0;
	temp = buffer;

	/* now print out the directory structure from the begining */
	string_len = sprintf(temp, "./");
	for (i = 0; i < path_depth; i++) {
		temp = temp + string_len;
		string_len = sprintf(buffer, "%s/", path_array[i]);
	}

	vfree(path_array);
	return buffer;
}

#if LINUX_VERSION_CODE > KERNEL_VERSION(3,9,0)
static ssize_t axfs_procfile_read(struct file *file, char __user *buffer, size_t count, loff_t *offset)
{
#if LINUX_VERSION_CODE > KERNEL_VERSION(3,10,0)
	struct inode *inode = file_inode(file);
#else
	struct inode *inode = file->f_dentry->d_inode;
#endif
	struct axfs_super *sbi;
	struct axfs_profiling_manager *manager;
#else
static int axfs_procfile_read(char *buffer,
				  char **buffer_location,
				  off_t offset, int buffer_length, int *eof,
				  void *data)
{
	struct axfs_profiling_manager *manager = (struct axfs_profiling_manager *)data;
	struct axfs_super *sbi;
#endif
	struct axfs_profiling_data *profile;

	u64 array_index;
	u64 loop_size, inode_page_offset, node_offset, inode_number, temp_len;
#if LINUX_VERSION_CODE > KERNEL_VERSION(3,9,0)
	u64 buffer_length;
#endif
	u64 print_len = 0;
	unsigned long addr;
	int len = 0;
	int i;
	char *temp, *name = NULL, *path;
	char numbers[50];

#if LINUX_VERSION_CODE > KERNEL_VERSION(3,9,0)
	manager = (struct axfs_profiling_manager *)PDE_DATA(inode);
#endif
	sbi = manager->sbi;
	loop_size = manager->size / sizeof(*profile);

#if LINUX_VERSION_CODE > KERNEL_VERSION(3,9,0)
	/* If all data has been sent then return */
	if (*offset >= loop_size)
		return 0;
#else
	/* If all data has been returned set EOF */
	if (offset >= loop_size) {
		*eof = 1;
		return 0;
	}
#endif

#if LINUX_VERSION_CODE > KERNEL_VERSION(3,9,0)
	temp = manager->temp;
	if (count > TEMP_BUFFER_SIZE) {
		buffer_length = TEMP_BUFFER_SIZE;
	} else {
		buffer_length = count;
	}

	/* print as much as the buffer can take */
	for (i = *offset; i < loop_size; i++) {
#else
	temp = buffer;

	/* print as much as the buffer can take */
	for (i = offset; i < loop_size; i++) {
#endif

		/* get the first profile data structure */
		profile = &(manager->profiling_data[i]);

		if (profile->count == 0)
			continue;

		inode_number = profile->inode_number;

		/* file names can be duplicated so we must print out the path */
		path = axfs_get_directory_path(manager, &len, inode_number);
		temp_len = len;

		/* get a pointer to the inode name */
		array_index = axfs_get_inode_array_index(sbi, inode_number);
		name = axfs_get_inode_name(sbi, inode_number);
		temp_len += strlen(name);

		/* need to convert the page number in the node area to
		   the page number within the file */
		node_offset = i;
		/* gives the offset of the node in the node list area
		   then substract that from the */
		inode_page_offset = node_offset - array_index;

		addr = (unsigned long)(inode_page_offset * PAGE_SIZE);

		/* now prepare the last part of the string */
		len = sprintf(numbers,",%lu,%lu\n", addr, profile->count);
		numbers[len] = 0;
		temp_len += len;

		if (temp_len > buffer_length) {
			printk(KERN_WARNING
			       "axfs: Error, profile line too for buffers.\n");
			vfree(path);
			return -ENOMEM;
		}

		if ((print_len + temp_len) > buffer_length) {
			vfree(path);
			break;
		}

		/* print it all out together */
		len = sprintf(temp, "%s%s%s", path, name, numbers);

		vfree(path);
		print_len += len;
		temp += len;
	}

#if LINUX_VERSION_CODE > KERNEL_VERSION(3,9,0)
	temp_len = copy_to_user(buffer, manager->temp, print_len);
	if(temp_len) {
		printk(KERN_WARNING
		       "axfs: Error, Not sure what happened.\n");
		return -ENOMEM;
	}
	*offset += print_len;
#else
	/* return the number of items printed.
	   This will be added to offset and passed back to us */
	*buffer_location = (char *)(i - offset);
#endif

	return print_len;
}

#if LINUX_VERSION_CODE > KERNEL_VERSION(3,9,0)
static ssize_t axfs_procfile_write(struct file *file, const char __user *buffer, size_t count, loff_t *offset)
{
#if LINUX_VERSION_CODE > KERNEL_VERSION(3,10,0)
	struct inode *inode = file_inode(file);
#else
	struct inode *inode = file->f_dentry->d_inode;
#endif
	char temp[5];
	int len, i;
#else
static int axfs_procfile_write(struct file *file,
				   const char *temp, unsigned long count,
				   void *data)
{
#endif
	struct axfs_profiling_manager *manager;
	struct axfs_super *sbi;

#if LINUX_VERSION_CODE > KERNEL_VERSION(3,9,0)
	manager = (struct axfs_profiling_manager *)PDE_DATA(inode);
	sbi = manager->sbi;

	if (count > 5)
		i = 5;
	else
		i = count;

	len = copy_from_user(temp, buffer, i);
	if (len) {
		printk(KERN_WARNING
		       "axfs: Error, Not sure what happened.\n");
		return -ENOMEM;
	}

#else
	manager = (struct axfs_profiling_manager *)data;
	sbi = manager->sbi;
#endif

	if ((count >= 2) && (0 == memcmp(temp, "on", 2))) {
		sbi->profiling_on = true;
	} else if ((count >= 3) && (0 == memcmp(temp, "off", 3))) {
		sbi->profiling_on = false;
	} else if ((count >= 5) && (0 == memcmp(temp, "clear", 5))) {
		memset(manager->profiling_data, 0, manager->size);
	} else {
		printk(KERN_INFO
		       "axfs: Unknown command.  Supported options are:\n");
		printk(KERN_INFO "\t\"on\"\tTurn on profiling\n");
		printk(KERN_INFO "\t\"off\"\tTurn off profiling\n");
		printk(KERN_INFO "\t\"clear\"\tClear profiling buffer\n");
	}

	return count;
}

static int axfs_create_proc_directory(void)
{
	if (axfs_proc_dir == NULL) {
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,25)
		axfs_proc_dir = proc_mkdir(AXFS_PROC_DIR_NAME, NULL);
#else
		axfs_proc_dir = proc_mkdir(AXFS_PROC_DIR_NAME, &proc_root);
#endif
		if (!axfs_proc_dir) {
			printk(KERN_WARNING
			       "axfs: Failed to create directory\n");
			return false;
		}
	}
	return true;
}

static void axfs_delete_proc_directory(void)
{
	/* Determine if there are any directory elements
	   and remove if all of the proc files are removed. */
	if (axfs_proc_dir != NULL) {
#if LINUX_VERSION_CODE > KERNEL_VERSION(3,9,0)
		remove_proc_entry(AXFS_PROC_DIR_NAME, NULL);
#else
		if (axfs_proc_dir->subdir == NULL) {
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,25)
			remove_proc_entry(AXFS_PROC_DIR_NAME, NULL);
#else
			remove_proc_entry(AXFS_PROC_DIR_NAME, &proc_root);
#endif
			axfs_proc_dir = NULL;
		}
#endif
	}
}

/******************************************************************************
 *
 * axfs_delete_proc_file
 *
 * Description:
 *   Will search through the proc directory for the correct proc file,
 *   then delete it
 *
 * Parameters:
 *    (IN) sbi- axfs superblock pointer to determine which proc file to remove
 *
 * Returns:
 *    The profiling manager pointer for the proc file.
 *
 *****************************************************************************/
static struct axfs_profiling_manager *axfs_delete_proc_file(struct axfs_super
							    *sbi)
{
	struct axfs_profiling_manager *manager;
#if LINUX_VERSION_CODE > KERNEL_VERSION(3,9,0)
	char file_name[20];
#else
	struct proc_dir_entry *current_proc_file;
	void *rv = NULL;
#endif

	if (!axfs_proc_dir)
		return NULL;

#if LINUX_VERSION_CODE > KERNEL_VERSION(3,9,0)
	manager = (struct axfs_profiling_manager *) sbi->profile_man;
	sprintf(file_name, "volume%d", manager->count);
	remove_proc_entry(file_name, axfs_proc_dir);
	return manager;
#else
	/* Walk through the proc file entries to find the matching sbi */
	current_proc_file = axfs_proc_dir->subdir;

	while (current_proc_file != NULL) {
		manager = current_proc_file->data;
		if (manager == NULL) {
			printk(KERN_WARNING
			       "axfs: Error removing proc file private "
			       "data was NULL.\n");
			rv = NULL;
			break;
		}
		if (manager->sbi == sbi) {
			/* we found the match */
			remove_proc_entry(current_proc_file->name,
					  axfs_proc_dir);
			rv = (void *)manager;
			break;
		}
		current_proc_file = axfs_proc_dir->next;
	}

	return (struct axfs_profiling_manager *)rv;
#endif
}
#if LINUX_VERSION_CODE > KERNEL_VERSION(3,9,0)

static const struct file_operations axfs_proc_fops = {
	.read		= axfs_procfile_read,
	.write		= axfs_procfile_write,
};
#endif

/******************************************************************************
 *
 * axfs_register_profiling_proc
 *
 * Description:
 *   Will register the instance of the proc file for a given volume.
 *
 * Parameters:
 *    (IN) manager - Pointer to the profiling manager for the axfs volume
 *
 * Returns:
 *    0 or error number
 *
 *****************************************************************************/
static int axfs_register_profiling_proc(struct axfs_profiling_manager *manager)
{
	int rv = 0;
	struct proc_dir_entry *proc_file;
	char file_name[20];

	if (!axfs_create_proc_directory()) {
		rv = -ENOMEM;
		goto out;
	}

	sprintf(file_name, "volume%d", proc_name_inc);
#if LINUX_VERSION_CODE > KERNEL_VERSION(3,9,0)
	proc_file = proc_create_data(file_name, 0644, axfs_proc_dir, &axfs_proc_fops, (void *) manager);
#else
	proc_file = create_proc_entry(file_name, (mode_t) 0644, axfs_proc_dir);
#endif
	if (proc_file == NULL) {
		remove_proc_entry(file_name, axfs_proc_dir);
		axfs_delete_proc_directory();
		rv = -ENOMEM;
		goto out;
	}
	manager->sbi->profile_man = (void *) manager;
	manager->count = proc_name_inc;
	proc_name_inc++;
#if LINUX_VERSION_CODE > KERNEL_VERSION(3,9,0)
#else
	proc_file->read_proc = axfs_procfile_read;
	proc_file->write_proc = axfs_procfile_write;
#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,30)
	proc_file->owner = THIS_MODULE;
#endif
	proc_file->mode = S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH;
	proc_file->uid = 0;
	proc_file->gid = 0;
	proc_file->data = manager;

#endif
	printk(KERN_DEBUG "axfs: Proc entry created\n");

      out:
	return rv;
}

/******************************************************************************
 *
 * axfs_unregister_profiling_proc
 *
 * Description:
 *   Will unregister the instance of the proc file for the volume that was
 *   mounted.  If this is the last volume mounted then the proc directory
 *   will also be removed.
 *
 * Parameters:
 *    (IN) sbi- axfs superblock pointer to determine which proc file to remove
 *
 * Returns:
 *    The profiling manager pointer for the proc file.
 *
 *****************************************************************************/
static struct axfs_profiling_manager *axfs_unregister_profiling_proc(struct
								     axfs_super
								     *sbi)
{
	struct axfs_profiling_manager *manager;
	manager = axfs_delete_proc_file(sbi);
	axfs_delete_proc_directory();
	return manager;
}

/******************************************************************************
 *
 * axfs_init_profiling
 *
 * Description:
 *   Creates the structures for tracking the page usage data and creates the
 *   proc file that will be used to get the data.
 *
 * Parameters:
 *    (IN) sbi- axfs superblock pointer
 *
 * Returns:
 *    true or false
 *
 *****************************************************************************/
int axfs_init_profiling(struct axfs_super *sbi)
{

	u32 num_nodes, num_inodes;
	struct axfs_profiling_manager *manager = NULL;
	struct axfs_profiling_data *profile_data = NULL;
	int err = -ENOMEM;

	/* determine the max number of pages in the FS */
	num_nodes = sbi->blocks;
	if (!num_nodes)
		return 0;

	manager = vmalloc(sizeof(*manager));
	if (!manager)
		goto out;

	profile_data = vmalloc(num_nodes * sizeof(*profile_data));
	if (!profile_data)
		goto out;

	memset(profile_data, 0, num_nodes * sizeof(*profile_data));

	/* determine the max number of inodes in the FS */
	num_inodes = sbi->files;

	manager->dir_structure = vmalloc(num_inodes * sizeof(u32 *));
	if (!manager->dir_structure)
		goto out;

	memset(manager->dir_structure, 0, (num_inodes * sizeof(u32 *)));

	manager->profiling_data = profile_data;
	manager->size = num_nodes * sizeof(*profile_data);
	manager->sbi = sbi;
	manager->temp = vmalloc(TEMP_BUFFER_SIZE);
	sbi->profiling_on = true;	/* Turn on profiling by default */
	sbi->profile_man = manager;

	err = axfs_init_profile_dir_structure(manager, num_inodes);
	if (err)
		goto out;

	err = axfs_register_profiling_proc(manager);
	if (err)
		goto out;

	return 0;

      out:
	vfree(manager->dir_structure);
	vfree(manager->temp);
	vfree(profile_data);
	vfree(manager);
	return err;
}

/******************************************************************************
 *
 * axfs_shutdown_profiling
 *
 * Description:
 *   Remove the proc file for this volume and release the memory in the
 *   profiling manager
 *
 * Parameters:
 *    (IN) sbi- axfs superblock pointer
 *
 * Returns:
 *    true or false
 *
 *****************************************************************************/
int axfs_shutdown_profiling(struct axfs_super *sbi)
{
	struct axfs_profiling_manager *manager;
	/* remove the proc file for this volume and release the memory in the
	   profiling manager */

	if (!sbi)
		return true;

	if (!sbi->profile_man)
		return true;

	manager = axfs_unregister_profiling_proc(sbi);

	if (manager == NULL)
		return false;

	vfree(manager->dir_structure);
	vfree(manager->temp);
	vfree(manager->profiling_data);
	vfree(manager);
	return true;
}

/******************************************************************************
 *
 * axfs_profiling_add
 *
 * Description:
 *    Log when a node is paged into memory by incrementing the count in the
 *    array profile data structure.
 *
 * Parameters:
 *    (IN) sbi- axfs superblock pointer
 *
 *    (IN) array_index - The offset into the nodes table of file (node number)
 *
 *    (IN) axfs_inode_number - Inode of the node to determine file name later
 *
 * Returns:
 *    none
 *
 *****************************************************************************/
void axfs_profiling_add(struct axfs_super *sbi, unsigned long array_index,
			unsigned int axfs_inode_number)
{
	unsigned long addr;
	struct axfs_profiling_manager *manager;
	struct axfs_profiling_data *profile_data;

	if (sbi->profiling_on != true)
		return;

	manager = (struct axfs_profiling_manager *)sbi->profile_man;
	addr = (unsigned long)manager->profiling_data;
	addr += array_index * sizeof(*profile_data);

	profile_data = (struct axfs_profiling_data *)addr;

	/* Record the inode number to determine the file name later. */
	profile_data->inode_number = axfs_inode_number;

	/* Increment the number of times the node has been paged in */
	profile_data->count++;
}

#else

int axfs_init_profiling(struct axfs_super *sbi)
{
	return 0;
}

int axfs_shutdown_profiling(struct axfs_super *sbi)
{
	return 0;
}

void axfs_profiling_add(struct axfs_super *sbi, unsigned long array_index,
			unsigned int axfs_inode_number)
{
}

#endif /* CONFIG_AXFS_PROFILING */

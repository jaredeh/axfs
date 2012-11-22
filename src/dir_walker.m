#import "dir_walker.h"
#import "inodes.h"
#import <stdio.h>

@implementation DirWalker

-(void) file_size: (uint64_t) size file_name: (char *) name {
	filename_size += strlen(name);
	filedata_size += size;
	number_of_files++;
	if (size <= acfg.page_size) {
		number_of_nodes++;
	} else {
		uint64_t d = size / acfg.page_size;
		if (size > d*acfg.page_size) {
			d++;
		}
		number_of_nodes += d;
	}
}

-(void) set_acfg_values {
	acfg.max_nodes = number_of_nodes;
	acfg.max_text_size = filename_size;
	acfg.max_number_files = number_of_files;
	acfg.max_filedata_size = filedata_size;
}

/*
NSFileTypeDirectory;
NSFileTypeRegular;
NSFileTypeSymbolicLink;
NSFileTypeSocket;
NSFileTypeCharacterSpecial;
NSFileTypeBlockSpecial;
NSFileTypeUnknown;
*/

-(void) size_up_dir {
	NSString *path;
	NSDirectoryEnumerator *de;
	NSDictionary *attribs;
	NSString *filetype;
	uint64_t size;
	char *name;
	
	de = [[NSFileManager defaultManager] enumeratorAtPath: rootpath];
	if (!de)
		return;
	
	while ((path = [de nextObject]))
	{
		attribs = [de fileAttributes];
		filetype = [attribs objectForKey:NSFileType];
		name = (char *)[[path lastPathComponent] UTF8String];
		if (filetype == NSFileTypeDirectory) {
			printf("directory:'%s'\n",[path UTF8String]);
			printf("  dir name: '%s' type: '%s'\n", name, [[attribs	objectForKey:NSFileType] UTF8String]);
			[self file_size: 0 file_name: name];
		} else if ((filetype == NSFileTypeCharacterSpecial) || (filetype == NSFileTypeBlockSpecial)) {
			[self file_size: 0 file_name: name];
		} else if ((filetype == NSFileTypeRegular) || (filetype == NSFileTypeSymbolicLink)) {
			size = (uint64_t)[[attribs objectForKey:NSFileSize] unsignedLongLongValue];
			printf("path:'%s'\n",[path UTF8String]);
			printf("  file name: '%s' type: '%s' size: '%i'\n", name, [[attribs objectForKey:NSFileType] UTF8String], (int) size);
			[self file_size: size file_name: name];
		} else if ((filetype == NSFileTypeSocket) || (filetype == NSFileTypeUnknown)) {
		}
	}
	[self set_acfg_values];
}

-(void) walk {
	NSString *original_path;
	NSString *path;
	NSFileManager *fm;
	NSDirectoryEnumerator *de;
	Inodes *inodes;
	//NSString *filetype;
	//uint64_t size;
	//char *name;
	
	fm = [NSFileManager defaultManager];
	original_path = [fm currentDirectoryPath];
	if ([fm changeCurrentDirectoryPath: rootpath] == NO) {
		NSLog(@"Couldn't chdir() to %@ from %@",rootpath,original_path);
		return;
	}

	de = [fm enumeratorAtPath: @"."];
	if (!de)
		return;

	inodes = [[Inodes alloc] init];
	while ((path = [de nextObject]))
	{
		//NSDictionary *attribs;
		//attribs = [de fileAttributes];

		[inodes addInode: path];

		//filetype = [attribs objectForKey:NSFileType];
		//name = (char *)[[path lastPathComponent] UTF8String];
		//size = (uint64_t)[[attribs objectForKey:NSFileSize] unsignedLongLongValue];
		//printf("path:'%s'\n",[path UTF8String]);
		//printf("  file name: '%s' type: '%s' size: '%i'\n", name, [[attribs objectForKey:NSFileType] UTF8String], (int) size);
	}
}

-(void) printstats {
	printf("filedata_size = %llu\n", filedata_size);
	printf("filename_size = %llu\n", filename_size);
	printf("number_of_files= %llu\n", number_of_files);
	printf("number_of_nodes= %llu\n", number_of_nodes);
}

-(id) init {
	if (!(self = [super init]))
		return self;
	rootpath = [NSString stringWithUTF8String: acfg.input];
	filename_size = 0;
	filedata_size = 0;
	number_of_files = 0;
	number_of_nodes = 0;

	return self;
}

-(void) free {}

@end


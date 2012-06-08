#import "dir_walker.h"
#import <stdio.h>

@implementation DirWalker

-(void) size_up_dir: (NSString *) rootpath {
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
			//printf("directory:'%s'\n",[path UTF8String]);
			//printf("  dir name: '%s' type: '%s'\n", name, [[attribs	objectForKey:NSFileType] UTF8String]);
		} else {
			size = (uint64_t)[[attribs objectForKey:NSFileSize] unsignedLongLongValue];
			//printf("path:'%s'\n",[path UTF8String]);
			//printf("  file name: '%s' type: '%s' size: '%i'\n", name, [[attribs objectForKey:NSFileType] UTF8String], (int) size);
			[self file_size: size file_name: name];
		}
	}
}

-(void) file_size: (uint64_t) size file_name: (char *) name {
	filename_size += strlen(name);
	filedata_size += size;
	number_of_files++;
}

-(void) printstats {
	NSLog(@"filedata_size = %llu\n", filedata_size);
	NSLog(@"filename_size = %llu\n", filename_size);
	NSLog(@"number_of_files= %llu\n", number_of_files);
}

-(void) initialize {}
-(void) free {}

@end


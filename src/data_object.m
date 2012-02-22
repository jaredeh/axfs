#import <Foundation/Foundation.h>
#import "data_object.h"

@implementation AxfsDataObject

-(void) file_size: (uint64_t) size file_name: (char *) name {
	filename_size += strlen(name);
	filedata_size += size;
	number_of_files++;
}

-(void) printstats {
	NSLog(@"filedata_size = %llu\n", filedata_size);
	NSLog(@"filename_size = %llu\n", filename_size);
	NSLog(@"number_of_files= %d\n", number_of_files);
}

@end

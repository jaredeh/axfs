#import <Foundation/NSObject.h>

@interface AxfsDataObject: NSObject {
	uint64_t filename_size;
	uint64_t filedata_size;
	uint64_t number_of_files;
}
-(void) file_size: (uint64_t) size file_name: (char *) name;
-(void) printstats;
@end

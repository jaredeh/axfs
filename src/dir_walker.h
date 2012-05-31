#import "data_object.h"
#import <Foundation/Foundation.h>

@interface AxfsDirWalker: NSObject {
	AxfsDataObject *DataObject;
}
-(void) walk: (NSString *) p;
-(void) setDataObject: (AxfsDataObject *) ado;
@end

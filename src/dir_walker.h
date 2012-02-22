#import <Foundation/NSObject.h>
#import "data_object.h"

@interface AxfsDirWalker: NSObject {
	AxfsDataObject *DataObject;
}
-(void) walk: (NSString *) p;
-(void) setDataObject: (AxfsDataObject *) ado;
@end

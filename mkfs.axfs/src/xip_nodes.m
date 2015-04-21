#import "xip_nodes.h"

@implementation XipNodes

-(bool) pageIsXip: (NSString *) path offset: (uint64_t) offset {
	NSMutableArray *array;
	NSLog(@"XipNodes - pageIsXip");
	NSLog(@"path:%@",path);
	NSLog(@"offset:%u",offset);
	array = [profile objectForKey: path];
	NSLog(@"XipNodes - pageIsXip ---2");
	if (array == NULL)
		return false;

	NSLog(@"XipNodes - pageIsXip ---3");
	if ([array containsObject:  [NSString stringWithFormat:@"%llu",offset]])
		return true;

	NSLog(@"XipNodes - pageIsXip ---4");

	return false;
}

-(void *) data {
	uint64_t i;
	struct page_struct *page;
	uint8_t *bd = data;

	if(cached) {
		return data;
	}
	cached = true;
	if (cdata)
		free(cdata);
	size = 0;
	for(i=0;i<place;i++) {
		page = pages[i];
		memcpy(bd, page->data, page->length);
		memset(bd + page->length, 0, acfg.page_size - page->length);
		size += acfg.page_size;
		bd += acfg.page_size;
	}
	return data;
}

-(void) readProfile {
	NSString *path;
	NSString *contents;
	NSArray *lines;

	if (acfg.profile == NULL)
		return;

	path = [NSString stringWithUTF8String: acfg.profile];
	contents = [NSString stringWithContentsOfFile: path 
	                     encoding: NSASCIIStringEncoding
	                     error: NULL];
	lines = [contents componentsSeparatedByCharactersInSet:
				[NSCharacterSet characterSetWithCharactersInString:@"\r\n"]];
	for (NSString* line in lines) {
    	if (line.length) {
    		NSArray *parts = [line componentsSeparatedByCharactersInSet:
									[NSCharacterSet characterSetWithCharactersInString:@","]];
        	if ([profile objectForKey: [parts objectAtIndex: 0]] == NULL)
        		[profile setObject: [NSMutableArray array] forKey: [parts objectAtIndex: 0]];
        	NSMutableArray *array = [profile objectForKey: [parts objectAtIndex: 0]];
        	[array addObject: [parts objectAtIndex: 1]];
        	NSLog(@"line: %@  %@", profile, [[parts objectAtIndex: 1] class]);
    	}
	}
	
}

-(id) init {
	if (!(self = [super init]))
		return self;

	profile = [NSMutableDictionary dictionary];
	[self readProfile];

	return self;
}

-(void) free {
	[super free];
	free(data);
}

@end

#import "opts_validator.h"

@implementation OptsValidator

-(void) initialize {
}

-(int) safe_strlen: (char *) str {
	if (str == NULL)
		return 0;
	return strlen(str);
}

-(bool) validate_compression {
	Compressor *comp;
	bool retval = true;

	if ([self safe_strlen: acfg.compression] < 1)
		return true;

	comp = [[Compressor alloc] init];
	[comp initialize];
	retval = [comp algorithm: acfg.compression];
	[comp free];
	[comp release];

	return retval;
}

-(bool) validate {
	if (([self safe_strlen: acfg.input] < 1) || ([self safe_strlen: acfg.output] < 1))
		return false;
	if (![self validate_compression])
		return false;
	return true;
}
-(void) free {
}

@end


#import "opts_validator.h"

@implementation OptsValidator

-(void) initialize {
}

-(int) safe_strlen: (char *) str {
	if (str == NULL)
		return 0;
	return strlen(str);
}

-(bool) is_directory: (char *) path {
	BOOL isdir;
	NSFileManager *fileManager = [[NSFileManager alloc] init];

	NSString *str = [[NSString alloc] initWithUTF8String:path];
	if ([fileManager fileExistsAtPath:str isDirectory:&isdir] && isdir)
		return true;
	return false;
}

-(bool) is_file: (char *) path {
	BOOL isdir;
	NSFileManager *fileManager = [[NSFileManager alloc] init];

	NSString *str = [[NSString alloc] initWithUTF8String:path];
	if ([fileManager fileExistsAtPath:str isDirectory:&isdir] && !isdir)
		return true;
	return false;
}

-(bool) validate_properfiles: (char **) msg {
	char buffer[256];
	memset(buffer,0,256);

	if ([self safe_strlen: acfg.input] < 1) {
		sprintf(buffer,"--input: has zero length\n");
	} else if (![self is_directory: acfg.input]) {
		sprintf(buffer,"--input %s: is not a directory\n",acfg.input);
	} else if ([self safe_strlen: acfg.output] < 1) {
		sprintf(buffer,"--output: has zero length\n");
	} else if ([self is_directory: acfg.output]) {
		sprintf(buffer,"--output %s: is not a directory\n",acfg.output);
	}

	if (strlen(buffer) != 0) {
		memcpy(*msg,buffer,strlen(buffer));
		return false;
	}

	if ([self safe_strlen: acfg.secondary_output] > 1) {
		if ([self is_directory: acfg.secondary_output]) {
			sprintf(buffer,"--secondary_output %s: can't be a directory\n",acfg.output);
		} else if (strlen(acfg.output) == strlen(acfg.secondary_output))
			if (memcmp(acfg.output,acfg.secondary_output,strlen(acfg.output)) == 0) {
				sprintf(buffer,"--output %s and --secondary_output %s:"
						       " can't be the same\n",acfg.output
						       ,acfg.secondary_output);
		}
	}

	if ([self safe_strlen: acfg.profile] > 1)
		if (![self is_file: acfg.profile])
			sprintf(buffer,"--profile %s: is not a directory\n",acfg.profile);

	if (strlen(buffer) != 0) {
		memcpy(*msg,buffer,strlen(buffer));
		return false;
	}

	return true;
}

-(bool) validate_compression: (char **) msg {
	Compressor *comp;

	if (acfg.compression == NULL) {
		return true;
	} else if ([self safe_strlen: acfg.compression] < 1) {
		sprintf(*msg,"--compression has zero length\n");
		return false;
	}

	comp = [[Compressor alloc] init];
	[comp initialize];
	if(![comp algorithm: acfg.compression])
		sprintf(*msg,"--compression %s: is not a supported algorithm\n",acfg.compression);

	[comp free];
	[comp release];

	if (strlen(*msg) != 0)
		return false;

	return true;
}

-(bool) validate_numbers: (char **) msg {

	if ((acfg.page_size == 0) && (acfg.page_size_str != NULL)) {
		sprintf(*msg,"--page_size %s: is not correct\n",acfg.page_size_str);
	} else if ((acfg.xip_size == 0) && (acfg.xip_size_str != NULL)) {
		sprintf(*msg,"--xip_size %s: is not correct\n",acfg.xip_size_str);
	} else if ((acfg.block_size == 0) && (acfg.block_size_str != NULL)) {
		sprintf(*msg,"--block_size %s: is not correct\n",acfg.block_size_str);
	}

	if (strlen(*msg) != 0)
		return false;

	return true;
}

-(bool) validate: (char **) msg {
	char buffer[256];
	memset(buffer,0,256);

	if (![self validate_properfiles: msg]) {
	} else if (![self validate_compression: msg]) {
	} else if (![self validate_numbers: msg]) {
	} else {
		return true;
	}

	return false;
}

-(void) free {
}

@end

bool do_opts_validator(char ** msg) {
	OptsValidator *ov;
	bool retval;

	memset(*msg,0,1024);
	ov = [[OptsValidator alloc] init];
	[ov initialize];
	retval = [ov validate: msg];
	[ov free];
	[ov release];
	return retval;
}

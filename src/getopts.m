#import "getopts.h"

@implementation GetOpts
-(void) dst: (char **) output src: (char *) opt {
	int len = strlen(opt) + 1;
	*output = malloc(len);
	memset(*output, 0, len);
	memcpy(*output, opt, strlen(opt));
}

-(void) value: (uint64_t *) output src: (char *) opt {
	NSString *str = [[NSString alloc] initWithUTF8String:opt];
	uint64_t num = (uint64_t)[str doubleValue];
	*output = num;
	[str release];
}

-(void) input: (char *) opt {
	[self dst: &acfg.input src: opt];
}
-(void) output: (char *) opt {
	[self dst: &acfg.output src: opt];
}
-(void) secondary_output: (char *) opt {
	[self dst: &acfg.secondary_output src: opt];
}
-(void) block_size: (char *) opt {
	[self value: &(acfg.block_size) src: opt];
}
-(void) xip_size: (char *) opt {
	[self value: &(acfg.xip_size) src: opt];
}
-(void) compression: (char *) opt {
	[self dst: &acfg.compression src: opt];
}
-(void) profile: (char *) opt {
	[self dst: &acfg.profile src: opt];
}
-(void) special: (char *) opt {
	[self dst: &acfg.special src: opt];
}

-(void) switch_long_options: (int) index optarg: (char *) optarg {
	switch (index) {
		case 0:
			[self input: optarg];
			break;
		case 1:
			[self output: optarg];
			break;
		case 2:
			[self secondary_output: optarg];
			break;
		case 3:
			[self block_size: optarg];
			break;
		case 4:
			[self xip_size: optarg];
			break;
		case 5:
			[self compression: optarg];
			break;
		case 6:
			[self profile: optarg];
			break;
		case 7:
			[self special: optarg];
			break;
		default:
			break;
	}
}

-(void) switch_short_options: (int) c index: (int) index optarg: (char *) optarg {
	switch (c) {
		case 0:
			//printf("\n-----------case 0\n");
			[self switch_long_options: index optarg: optarg];
			break;
		case 'i':
			//printf("\n-----------case i\n");
			[self input: optarg];
			break;
		case 'o':
			[self output: optarg];
			break;
		case 'd':
			[self secondary_output: optarg];
			break;
		case 'b':
			[self block_size: optarg];
			break;
		case 'x':
			[self xip_size: optarg];
			break;
		case 'c':
			[self compression: optarg];
			break;
		case 'p':
			[self profile: optarg];
			break;
		case 's':
			[self special: optarg];
			break;
		default:
			break;
	}
}

-(void) argc: (int) count argv: (char **) v {
	static struct option long_options[] = {
		{"input", 1, 0, 0},
		{"output", 1, 0, 0},
		{"secondary_output", 1, 0, 0},
		{"block_size", 1, 0, 0},
		{"xip_size", 1, 0, 0},
		{"compression", 1, 0, 0},
		{"profile", 1, 0, 0},
		{"special", 1, 0, 0},
		{NULL, 0, NULL, 0}
	};
	const char * short_options = "i:o:d:b:x:c:p:s:";
	int index = 0;
	int c;
	argc = count;
	argv = v;

	while (1) {
		c = getopt_long(argc, argv, short_options, long_options, &index);
		//printf("c: %i index: %i optarg: '%s'\n", c, index, optarg);

		if (c == -1)
			break;

		[self switch_short_options: c index: index optarg: optarg];
	}
}
-(void) initialize {
}
-(void) free {
}
@end

/*
 *********
 -i,--input == input directory
 -o,--output == binary output file, the XIP part
 -d,--secondary_output == second binary output 
 -b,--block_size == compression block size
 -x,--xip_size == xip size of image
 -c,--compression == compression library
 -p,--profile == list of XIP pages
 -s,--special == special modes of execution
 *********
 */
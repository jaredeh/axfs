#import "getopts.h"

@implementation GetOpts
-(void) dst: (char **) output src: (char *) opt {
	int len = strlen(opt) + 1;
	*output = malloc(len);
	memset(*output, 0, len);
	memcpy(*output, opt, strlen(opt));
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
-(void) page_size: (char *) opt {
	[self convert_arg: opt dst: &(acfg.page_size)];
	[self dst: &acfg.page_size_str src: opt];
}
-(void) block_size: (char *) opt {
	[self convert_arg: opt dst: &(acfg.block_size)];
	[self dst: &acfg.block_size_str src: opt];
}
-(void) xip_size: (char *) opt {
	[self convert_arg: opt dst: &(acfg.xip_size)];
	[self dst: &acfg.xip_size_str src: opt];
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

-(bool) is_number: (char) c {
	switch(c) {
		case '0':
			break;
		case '1':
			break;
		case '2':
			break;
		case '3':
			break;
		case '4':
			break;
		case '5':
			break;
		case '6':
			break;
		case '7':
			break;
		case '8':
			break;
		case '9':
			break;
		default:
			return false;
	}
	return true;
}

-(uint64_t) char_to_hex: (char) c multi: (uint64_t) i {
	uint64_t j = 1;
	int k;

	for(k=0;k<(i-1);k++) {
		j = j * 16;
	}

	switch(c) {
		case '0':
			return 0;
		case '1':
			return 1 * j;
		case '2':
			return 2 * j;
		case '3':
			return 3 * j;
		case '4':
			return 4 * j;
		case '5':
			return 5 * j;
		case '6':
			return 6 * j;
		case '7':
			return 7 * j;
		case '8':
			return 8 * j;
		case '9':
			return 9 * j;
		case 'a':
			return 10 * j;
		case 'b':
			return 11 * j;
		case 'c':
			return 12 * j;
		case 'd':
			return 13 * j;
		case 'e':
			return 14 * j;
		case 'f':
			return 15 * j;
		case 'A':
			return 10 * j;
		case 'B':
			return 11 * j;
		case 'C':
			return 12 * j;
		case 'D':
			return 13 * j;
		case 'E':
			return 14 * j;
		case 'F':
			return 15 * j;
		default:
			return 0;
	}
}

-(bool) is_hex: (char *) opt value: (uint64_t *) output {
	int i = 0;
	int len = strlen(opt);

	if (opt[0] != '0')
		return false;
	if ((opt[1] != 'x') && (opt[1] != 'X'))
		return false;

	for (i=1; i<(len-1); i++) {
		*output += [self char_to_hex: opt[len - i] multi: i];
	}
	return true;
}

-(uint64_t) multipliers: (char) c {
	if ((c =='b') || (c == 'B')) {
		return 1;	
	} else if ((c =='k') || (c == 'K')) {
		return 1024;
	} else if ((c =='m') || (c == 'M')) {
		return 1048576;
	} else if ((c =='g') || (c == 'G')) {
		return 1073741824;
	} else if ([self is_number: c]) {
		return 1;
	}
	return 0;
}

-(uint64_t) calc_multiplier: (char *) opt {
	int len = strlen(opt);

	//if len is 1 then it's just a number
	if(len < 2)
		return 1;

	//We shouldn't allow bB, Bb, BB, bb
	if (((opt[len-2] == 'b') || (opt[len-2] == 'B')))
			return 0;

	//Given 1024XY, if X is not a number then Y must be 'B' or 'b'
	if (![self is_number: opt[len-2]]) {
		if (!((opt[len-1] == 'b') || (opt[len-1] == 'B')))
			return 0;
	}
	return [self multipliers: opt[len-2]] * [self multipliers: opt[len-1]];
}

-(void) cstring_to_i: (char *) opt dst:(uint64_t *) output {
	NSString *str = [[NSString alloc] initWithUTF8String:opt];
	uint64_t num = (uint64_t)[str doubleValue];
	*output = num;
	[str release];
}

-(void) convert_arg: (char *) opt dst: (uint64_t *) output {
	if ([self is_hex: opt value: output])
		return;
	[self cstring_to_i: opt dst: output];
	*output	= *output * [self calc_multiplier: opt];
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
			[self page_size: optarg];
			break;
		case 4:
			[self block_size: optarg];
			break;
		case 5:
			[self xip_size: optarg];
			break;
		case 6:
			[self compression: optarg];
			break;
		case 7:
			[self profile: optarg];
			break;
		case 8:
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
		case 'g':
			[self page_size: optarg];
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
		{"page_size", 1, 0, 0},
		{"block_size", 1, 0, 0},
		{"xip_size", 1, 0, 0},
		{"compression", 1, 0, 0},
		{"profile", 1, 0, 0},
		{"special", 1, 0, 0},
		{NULL, 0, NULL, 0}
	};
	const char * short_options = "i:o:d:g:b:x:c:p:s:";
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

void do_getopts(int argc, const char *argv[]) {
	GetOpts *go = [[GetOpts alloc] init];
	[go initialize];
	[go argc: argc argv: (char **) argv];
	[go free];
	[go release];
}

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
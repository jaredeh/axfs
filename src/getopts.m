#import "getopts.h"

@implementation GetOpts
-(void) input: (char *) opt {
}
-(void) output: (char *) opt {
}
-(void) secondary_output: (char *) opt {
}
-(void) block_size: (char *) opt {
}
-(void) xip_size: (char *) opt {
}
-(void) compression: (char *) opt {
}
-(void) profile: (char *) opt {
}
-(void) special: (char *) opt {
}
-(void) argc: (int) c argv: (char **) v {
    argc = c;
    argv = v;
}
-(void) config: (struct axfs_config *) f {
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
    config = f;
    
    while ((c = getopt_long(argc, argv, short_options, long_options, &index)) != -1) {
        switch (c) {
            case 0:
                printf ("option %s", long_options[index].name);
                if (optarg)
                    printf (" with arg %s", optarg);
                printf ("\n");
                break;
            case 'i':
                printf ("option i with value '%s'\n", optarg);
                [self input: optarg];
                break;
            default:
                break;
        }

    }
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
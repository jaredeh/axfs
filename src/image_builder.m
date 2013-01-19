#import "image_builder.h"

@implementation ImageBuilder

-(void) setupObjs {
	printf("ImageBuilder setupObjs {\n");
	aobj.strings = [[Strings alloc] init];
	aobj.nodes = [[Nodes alloc] init];
	aobj.xip = [aobj.nodes xip];
	aobj.byte_aligned = [aobj.nodes byte_aligned];
	aobj.compressed = [aobj.nodes compressed];
	aobj.modes = [[Modes alloc] init];
	aobj.inodes = [[Inodes alloc] init];
	aobj.superblock = [[Super alloc] init];
	aobj.regdesc = [[RegionDescriptors alloc] init];
	aobj.pages = [[Pages alloc] init];
	sb = aobj.superblock;
	rd = aobj.regdesc;
	printf("} ImageBuilder setupObjs\n\n");
}

-(void) setupRegions {
	struct axfs_region_descriptors *r = &aobj.regions;
	printf("ImageBuilder setupRegions {\n");
	r->strings = [aobj.strings region];
	r->xip = [aobj.xip region];
	r->byte_aligned = [aobj.byte_aligned region];
	r->compressed = [aobj.compressed region];
	r->node_type = [[aobj.nodes nodeType] region];
	r->node_index = [[aobj.nodes nodeIndex] region];
	r->cnode_offset = [[aobj.compressed cnodeOffset] region];
	r->cnode_index = [[aobj.compressed cnodeIndex] region];
	r->banode_offset = [[aobj.byte_aligned banodeOffset] region];
	r->cblock_offset = [[aobj.compressed cblockOffset] region];
	r->inode_file_size = [[aobj.inodes fileSizeIndex] region];
	r->inode_name_offset = [[aobj.inodes nameOffset] region];
	r->inode_num_entries = [[aobj.inodes numEntries] region];
	r->inode_mode_index = [[aobj.inodes modeIndex] region];
	r->inode_array_index = [[aobj.inodes arrayIndex] region];
	r->modes = [[aobj.modes modesTable] region];
	r->uids = [[aobj.modes uids] region];
	r->gids = [[aobj.modes gids] region];
	printf("} ImageBuilder setupRegions\n\n");
}

-(void) buildPart: (id) obj name: (char *) name {
	uint64_t input_offset;
	uint64_t actual_offset;
	uint64_t padding_size;
	struct data_segment *ds;

	input_offset = data_segments[current_segment-1].end;

	[obj fsoffset: input_offset];
	actual_offset = [obj fsoffset];
	padding_size = actual_offset - input_offset;

	printf("\tactual_offset=%d - input_offset=%d\n",(int)actual_offset ,(int)input_offset);
	if (padding_size != 0) {
		printf("\tpadding_size=%i\n",padding_size);
		ds = &data_segments[current_segment];
		current_segment++;
		ds->data = malloc(padding_size);
		ds->start = input_offset;
		ds->size = padding_size;
		ds->end = ds->start + ds->size;
		memset(ds->data,0,padding_size);
	}
	ds = &data_segments[current_segment];
	current_segment++;
	ds->data = [obj data];
	ds->start = actual_offset;
	ds->size = [obj size];
	ds->end = ds->start + ds->size;
	ds->name = name;
	printf("\tname='%s' ds[start=%d size=%d end=%d data=0x%08x]\n",name,(int)ds->start,(int)ds->size,(int)ds->end, ds->data);
	//printf("\tdata[%s]\n",ds->data+1);
}

-(void) hashImage {
	hash_state md;
	int i = 0;
	unsigned char *d;
	unsigned long len;
	unsigned char hash[40];

	memset(hash,0,40);

	sha1_init(&md);

	while (i < AXFS_MAX_DATASSEGMENTS) {
		d = (unsigned char *)data_segments[i].data;
		len = (unsigned long)data_segments[i].size;
		if (d == NULL)
			break;
		if (len != 0)
			sha1_process(&md, d, len);
		i++;
	}
	sha1_done(&md, hash);
	[sb do_digest: hash];
}

-(void) writeFile: (char *) filename size: (uint64_t) filesize fsoffset: (uint64_t *) offset {
	NSFileHandle *file;
	NSString *path;
	NSMutableData *buffer;
	uint64_t data_written = 0;
	int i = 0;

	printf("ImageBuilder writeFile {\n");
	if (filename == NULL) {
		[NSException raise: @"Bad file" format: @"-- filename is NULL"];
	}

	//printf("ImageBuilder writeFile %s data_written=%i filesize=%i\n",filename,data_written,filesize);

	path = [NSString stringWithUTF8String: filename];

	//printf("ImageBuilder writeFile %s data_written=%i filesize=%i\n",filename,data_written,filesize);

	[[NSFileManager defaultManager] createFileAtPath: path contents: nil attributes: nil];
	file = [NSFileHandle fileHandleForUpdatingAtPath: path];
	if (file == nil)
		[NSException raise: @"Bad file" format: @" -- Failed to open file at path=%@", path];

	while ((data_written <= filesize) && (i < current_segment)){
		uint64_t bytes_to_write;
		uint8_t *d_ptr;
		int j = i;
		int k;

		i++;

		//printf("\tImageBuilder writeFile i=%i j=%i data_written=%i\n",i,j,data_written);

		if (i >= AXFS_MAX_DATASSEGMENTS) {
			[NSException raise: @"last data_segment" format: @"i >= AXFS_MAX_DATASSEGMENTS => %d >= %d",i,AXFS_MAX_DATASSEGMENTS];
		}
		if (data_segments[j].data == NULL) {
			[NSException raise: @"Hit empty data_segment" format: @"data_segments[%d]->data == NULL with data_written=%d, offset=%d, and filesize=%d", j, data_written, offset, filesize];
		}

		//not there yet, so let's look at the next one
		if (*offset >= data_segments[j].end) {
			printf("wImageBuilder writeFile\n");
			continue;
		}

		d_ptr = (uint8_t *) data_segments[j].data;
		d_ptr += data_segments[j].written;

		bytes_to_write = data_segments[j].size - data_segments[j].written;
		//printf("\t\t1 ImageBuilder writeFile j=%i data_written=%i bytes_to_write=%i\n",j,data_written,bytes_to_write);

		if ((filesize - data_written) < bytes_to_write) {
			bytes_to_write = filesize - data_written;
		}
		//printf("\t\t2 ImageBuilder writeFile j=%i data_written=%i bytes_to_write=%i\n",j,data_written,bytes_to_write);


		buffer = [NSMutableData dataWithBytes: d_ptr length: bytes_to_write];
		data_written += bytes_to_write;
		printf("\t3 ImageBuilder writeFile name='%s' j=%i data_written=%i bytes_to_write=%i\n",data_segments[j].name,j,data_written,bytes_to_write);
		printf("[");
		for(k=0;k<bytes_to_write;k++) {
			printf("%02x",d_ptr[k]);
		}
		printf("]\n");
		[file writeData: buffer];
	}
	[file closeFile];
	*offset += data_written;
	printf("} ImageBuilder writeFile\n\n");
}

-(void) build {
	uint64_t offset = 0;
	printf("ImageBuilder build {\n");

	[aobj.xip data];
	[aobj.strings data];
	[aobj.byte_aligned data];
	[aobj.compressed data];
	[aobj.inodes data];
	[aobj.modes data];

	data_segments[0].start = 0;
	data_segments[0].size = [sb size];
	data_segments[0].end = [sb size];
	data_segments[0].name = "superblock";
	[self buildPart: rd name: "region descriptors"];
	[self buildPart: [aobj.nodes nodeType] name: "nodeType"];
	[self buildPart: [aobj.nodes nodeIndex] name: "nodeIndex"];
	[self buildPart: [aobj.compressed cnodeOffset] name: "cnodeOffset"];
	[self buildPart: [aobj.compressed cnodeIndex] name: "cnodeIndex"];
	[self buildPart: [aobj.byte_aligned banodeOffset] name: "banodeOffset"];
	[self buildPart: [aobj.compressed cblockOffset] name: "cblockOffset"];
	[self buildPart: [aobj.inodes fileSizeIndex] name: "fileSizeIndex"];
	[self buildPart: [aobj.inodes nameOffset] name: "nameOffset"];
	[self buildPart: [aobj.inodes numEntries] name: "numEntries"];
	[self buildPart: [aobj.inodes modeIndex] name: "modeIndex"];
	[self buildPart: [aobj.inodes arrayIndex] name: "arrayIndex"];
	[self buildPart: [aobj.modes modesTable] name: "modesTable"];
	[self buildPart: [aobj.modes uids] name: "uids"];
	[self buildPart: [aobj.modes gids] name: "gids"];
	[self buildPart: aobj.xip name: "xip"];
	printf("strings {\n");
	[self buildPart: aobj.strings name: "strings"];
	printf("} strings\n\n");
	[self buildPart: aobj.byte_aligned name: "bytealigned"];
	[self buildPart: aobj.compressed name: "compressed"];

	acfg.real_imagesize = data_segments[current_segment-1].end;

	data_segments[0].data = [sb data];
	[self hashImage];
	data_segments[0].data = [sb data];

	//validate image is okay

	//write out data to files
	if ((acfg.secondary_output != NULL) && (acfg.mmap_size != 0)) {
		[self writeFile: acfg.output size: acfg.mmap_size fsoffset: &offset];
		[self writeFile: acfg.secondary_output size: acfg.real_imagesize - acfg.mmap_size fsoffset: &offset];
	} else {
		[self writeFile: acfg.output size: acfg.real_imagesize fsoffset: &offset];
	}

	if (offset != acfg.real_imagesize)
		[NSException raise: @"Write incomplete" format: @"offset != acfg.real_imagesize %d != %d",offset,acfg.real_imagesize];
	printf("} ImageBuilder build\n\n");
}

-(void) sizeup {
	printf("ImageBuilder sizeup {\n");
	aobj.dirwalker = [[DirWalker alloc] init];
	dw = aobj.dirwalker;
	[dw size_up_dir];
	[dw printstats];
	printf("} ImageBuilder sizeup\n\n");
}

-(void) walk {
	printf("ImageBuilder walk {\n");
	[dw walk];
	[dw printstats];
	printf("} ImageBuilder walk\n\n");
}

-(id) init {
	if (!(self = [super init]))
		return self;

	current_segment = 1;
	return self;
}

-(void) free {
	[aobj.strings free];
	[aobj.xip free];
	[aobj.byte_aligned free];
	[aobj.compressed free];
	[aobj.inodes free];
	[aobj.modes free];
}

@end

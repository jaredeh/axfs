#import "image_builder.h"

@implementation ImageBuilder

-(void) setupObjs {
	aobj.strings = [[Strings alloc] init];
	aobj.nodes = [[Nodes alloc] init];
	aobj.xip = [aobj.nodes xip];
	aobj.byte_aligned = [aobj.nodes byte_aligned];
	aobj.compressed = [aobj.nodes compressed];
	aobj.inodes = [[Inodes alloc] init];
	aobj.modes = [[Modes alloc] init];
	aobj.superblock = [[Super alloc] init];
	aobj.regdesc = [[RegionDescriptors alloc] init];
	sb = aobj.superblock;
	rd = aobj.regdesc;
}

-(void) setupRegions {
	struct axfs_region_descriptors *r = &aobj.regions;
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
	r->inode_num_entries = [[aobj.inodes numEntriescblockOffset] region];
	r->inode_mode_index = [[aobj.inodes modeIndex] region];
	r->inode_array_index = [[aobj.inodes arrayIndex] region];
	r->modes = [[aobj.modes modesTable] region];
	r->uids = [[aobj.modes uids] region];
	r->gids = [[aobj.modes gids] region];
}

-(void) buildPart: (id) obj {
	uint64_t input_offset;
	uint64_t actual_offset;
	uint64_t padding_size;
	struct data_segment *ds;

	input_offset = data_segments[current_segment-1].end;

	[obj fsoffset: input_offset];
	actual_offset = [obj fsoffset];
	padding_size = actual_offset - input_offset;

	printf("actual_offset=%d - input_offset=%d\n",actual_offset ,input_offset);
	if (padding_size != 0) {
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
	printf("ds[start=%d size=%d end=%d]\n",ds->start,ds->size,ds->end);

}

-(void) hashImage {

}

-(void) writeFile: (char *) filename size: (uint64_t) filesize fsoffset: (uint64_t *) offset {
	NSFileHandle *file;
	NSString *path;
	NSMutableData *buffer;
	uint64_t data_written = 0;
	int i = 0;

	if (filename == NULL) {
		[NSException raise: @"Bad file" format: @"-- filename is NULL"];
	}

	path = [NSString stringWithUTF8String: filename];

	[[NSFileManager defaultManager] createFileAtPath: path contents: nil attributes: nil];
	file = [NSFileHandle fileHandleForUpdatingAtPath: path];
	if (file == nil)
		[NSException raise: @"Bad file" format: @" -- Failed to open file at path=%@", path];

	while (data_written < filesize) {
		uint64_t bytes_to_write;
		uint8_t *d_ptr;
		int j = i;

		i++;

		if (i >= AXFS_MAX_DATASSEGMENTS) {
			[NSException raise: @"last data_segment" format: @"i >= AXFS_MAX_DATASSEGMENTS => %d >= %d",i,AXFS_MAX_DATASSEGMENTS];
		}
		if (data_segments[j].data == NULL) {
			[NSException raise: @"Hit empty data_segment" format: @"data_segments[%d]->data == NULL with data_written=%d, offset=%d, and filesize=%d", j, data_written, offset, filesize];
		}

		//not there yet, so let's look at the next one
		if (*offset >= data_segments[j].end) 
			continue;

		d_ptr = (uint8_t *) data_segments[j].data;
		d_ptr += data_segments[j].written;

		bytes_to_write = data_segments[j].size - data_segments[j].written;
		if ((filesize - data_written) > bytes_to_write) {
			bytes_to_write = filesize - data_written;
		}

		buffer = [NSMutableData dataWithBytes: d_ptr length: bytes_to_write];
		data_written += bytes_to_write;

		[file writeData: buffer];
	}
	[file closeFile];
	*offset += data_written;
}

-(void) build {
	uint64_t offset = 0;

	[self setupObjs];
	[self setupRegions];

	[aobj.xip data];
	[aobj.strings data];
	[aobj.byte_aligned data];
	[aobj.compressed data];

	data_segments[0].start = 0;
	data_segments[0].size = [sb size];
	data_segments[0].end = [sb size];
	[self buildPart: rd];
	[self buildPart: [aobj.nodes nodeType]];
	[self buildPart: [aobj.nodes nodeIndex]];
	[self buildPart: [aobj.compressed cnodeOffset]];
	[self buildPart: [aobj.compressed cnodeIndex]];
	[self buildPart: [aobj.byte_aligned banodeOffset]];
	[self buildPart: [aobj.compressed cblockOffset]];
	[self buildPart: [aobj.inodes fileSizeIndex]];
	[self buildPart: [aobj.inodes nameOffset]];
	[self buildPart: [aobj.inodes numEntriescblockOffset]];
	[self buildPart: [aobj.inodes modeIndex]];
	[self buildPart: [aobj.inodes arrayIndex]];
	[self buildPart: [aobj.modes modesTable]];
	[self buildPart: [aobj.modes uids]];
	[self buildPart: [aobj.modes gids]];
	[self buildPart: aobj.xip];
	[self buildPart: aobj.strings];
	[self buildPart: aobj.byte_aligned];
	[self buildPart: aobj.compressed];

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
}

-(void) sizeup {
	aobj.dirwalker = [[DirWalker alloc] init];
	dw = aobj.dirwalker;
	[dw size_up_dir];
	[dw printstats];
}

-(void) walk {
	[dw walk];
	[dw printstats];
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

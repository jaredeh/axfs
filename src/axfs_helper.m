#import "axfs_helper.h"
#include <dirent.h>

@implementation NSObject (axfs)


-(uint64_t) countFiles: (char *) path {
	uint64_t file_count = 0;
	DIR * dirp;
	struct dirent * entry;

	dirp = opendir(path);

	if (!dirp) {
		[NSException raise: @"Bad dir" format: @"Failed to open dir at path=%@",path];
	}
	while ((entry = readdir(dirp)) != NULL) {
		if (strcmp(entry->d_name,".") == 0) {
					printf("entry='%s' . \n",entry->d_name);
		} else if (strcmp(entry->d_name,"..") == 0) {
					printf("entry='%s' .. \n",entry->d_name);
		} else {
					printf("entry='%s'\n",entry->d_name);
			file_count++;
		}
	}

	closedir(dirp);
	printf("file_count=%i\n",file_count);
	return file_count;
}

-(uint64_t) alignNumber: (uint64_t) number bytes: (uint64_t) d {
	uint64_t q;
	uint64_t r;

	if (d == 0)
		d = 1;

	q = number / d;
	r = number % d;

	if (r == 0)
		return number;

	return d*(q+1);
}

-(uint8_t) outputByte: (uint64_t) datum byte: (uint8_t) b {
	uint64_t mask;
	uint64_t byte;
	int i;

	mask = 0xFF;
	for(i=0; i<b; i++) {
		mask = mask << 8;
	}
	byte = datum & mask;
	for(i=0; i<b; i++) {
		byte = byte >> 8;
	}
	return (uint8_t) byte;
}

-(uint8_t *) outputDatum: (uint64_t) datum depth: (uint8_t) depth buffer: (uint8_t *) buffer {
	int i;
	
	//printf("output datum 0x%016llx\n",(long long unsigned int)datum);
	for(i=0; i<depth; i++) {
		*buffer = [self outputByte: datum byte: depth-1-i];
		buffer++;
	}
	return buffer;
}

-(uint8_t *) bigEndianize: (uint64_t) number ptr: (void *) vptr bytes: (int) j {
	int i, l;
	uint8_t *ptr = vptr;
	for(i=0; i<j; i++) {
		l = [self outputByte: number byte: i];
		ptr[(j-1)-i] = l;
	}
	//i++;
	ptr += i;
	return ptr;
}

-(uint8_t *) bigEndianizea: (uint64_t) number ptr: (void *) vptr bytes: (int) j {
	int i, l;
	uint8_t *ptr = vptr;
	uint8_t *v = vptr;
	for(i=0; i<j; i++) {
		l = [self outputByte: number byte: i];
		printf("l=%i i=%i j=%i\n",l,i,j);
		ptr[(j-1)-i] = l;
	}
	//i++;
	ptr += i;
	printf("%02x %02x %02x %02x %02x %02x %02x %02x \n",v[7],v[6],v[5],v[4],v[3],v[2],v[1],v[0]);
	return ptr;
}

-(uint8_t *) bigEndian64: (uint64_t) number ptr: (void *) ptr {
	return [self bigEndianize: number ptr: ptr bytes: 8];
}

-(uint8_t *) bigEndian64a: (uint64_t) number ptr: (void *) ptr {
	return [self bigEndianizea: number ptr: ptr bytes: 8];
}

-(uint8_t *) bigEndian32: (uint32_t) number ptr: (void *) ptr {
	return [self bigEndianize: (uint64_t) number ptr: ptr bytes: 4];
}

-(uint8_t *) bigEndian16: (uint16_t) number ptr: (void *) ptr {
	return [self bigEndianize: (uint64_t) number ptr: ptr bytes: 2];
}

-(uint8_t *) bigEndianByte: (uint8_t) number ptr: (void *) ptr {
	return [self bigEndianize: (uint64_t) number ptr: ptr bytes: 1];
}

@end
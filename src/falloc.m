#import "falloc.h"
#import <stdio.h>
#import <fcntl.h> //for O_RDWR open() write() and fsync()
#import <unistd.h> //for close() and lseek()
#import <sys/mman.h> //for mmap()
#import <sys/stat.h> //for mode_t

@implementation falloc
-(void *) allocSize: (uint64_t) allocsize path: (char *) pathname {
	int bytes_written;

	size = allocsize;
	path = pathname;
	
	fd = open(path, (O_CREAT | O_TRUNC | O_RDWR), (S_IFREG | S_IRWXU));
	if ( fd < 0 ) {
		perror("open() error");
		return (void *) (unsigned long) fd;
	}

	lseek( fd, ((off_t) size) - 1, SEEK_SET);
	bytes_written = write(fd, "", 1 );
	if (bytes_written != 1 ) {
		perror("write error. ");
		return (void *) -1;
	}
	lseek( fd, 0, SEEK_SET);

	data = mmap(NULL, size, PROT_WRITE, MAP_SHARED, fd, 0);
	
	if ( data == MAP_FAILED ) {
		perror("mmap error. " );
		return (void *) -1;
	}
	return data;
}

-(void) initialize {}

-(void) free {
	close(fd);
	// TODO use 'path' to unlink file
}

@end

/*
 * Copyright 2006 Sony Corporation
 *
 * bload.c
 *    load an image file to memory
 * Usage:
 *    bload FILE PHYSADDR
 *
 *      FILE: file pathname
 *      PHYSADDR: address, eg: 0x80000000
 */

#include<stdio.h>
#include<sys/types.h>
#include<sys/stat.h>
#include<fcntl.h>
#include<stdlib.h>
#include<unistd.h>
#include<sys/mman.h>
#include<string.h>

#define PAGEMASK 0xfff
#define BUFFER_SIZE 16384

int main(int argc, char **argv)
{
       const char *file;
        unsigned long physaddr, page, offset, end, pagedsize;
        struct stat statbuf;
        int ans, infd, memfd, nread;
        off_t size;
        void *mapped;
        char *ptr;
        static char buf[BUFFER_SIZE];

        if (argc != 3) {
                fprintf(stderr, "usage: %s FILE PHYSADDR\n", argv[0]);
                exit(1);
        }
        file = argv[1];
        physaddr = strtoul(argv[2], NULL, 0);

        ans = stat(file,&statbuf);
        if (ans<  0) {
                perror("bload: stat");
                exit(1);
        }
        size = statbuf.st_size;

        page = physaddr&  ~PAGEMASK;
        offset = physaddr&  PAGEMASK;
        end = offset + size;
        pagedsize = (end + PAGEMASK)&  ~PAGEMASK;
        printf("filesize=0x%lx addr=0x%lx pagedsize=0x%lx\n",
               size, physaddr, pagedsize);

        infd = open(file, O_RDONLY);
        if (infd<  0) {
                perror("bload: open(file)");
                exit(1);
        }

        memfd = open("/dev/mem", O_RDWR|O_SYNC);
        if (memfd<  0) {
                perror("bload: open(/dev/mem)");
                exit(1);
        }
        printf("pagedsize : %d , page %d \n", pagedsize,page);
        mapped = mmap(NULL, pagedsize, PROT_WRITE, MAP_SHARED,
                      memfd, page);
        if (mapped == MAP_FAILED) {
                perror("bload: mmap");
                exit(1);
        }
        ptr = (char *)mapped + offset;
        while ((nread = read(infd, buf, BUFFER_SIZE))>  0) {
                memcpy(ptr, buf, nread);
                ptr += nread;
        }
        if (nread<  0) {
                perror("bload: read");
                exit(1);
        }

        if (munmap(mapped, pagedsize)<  0) {
                perror("bload: munmap");
                exit(1);
        }
        close(memfd);
        close(infd);
        return 0;
}


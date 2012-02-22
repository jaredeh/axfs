#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>
#include <sys/types.h>
#ifndef __CYGWIN32__
#include <sys/dir.h>
#endif
#include <dirent.h>

#include "CuTest.h"

#define BUFFERSIZE 1024
#define MAX_DIR_PATH 2048


struct dirent *readdir(DIR *dirp);

int RunIndividualTests(char *function_name)
{
	int error;
	char runbuffer[BUFFERSIZE];
	
	sprintf(runbuffer,"./%s/test",function_name, function_name);

	printf("------ Testing %s() ------\n",function_name);
	error = system(runbuffer);
	if(error)
	{
		printf("Error opening %s\n\n", runbuffer);
		return 0;
	}

	return 0;
}

int RecurseFunctions(char *c_files_name)
{
	struct dirent *function_entry;
	DIR *function_dir;
	char openbuffer[MAX_DIR_PATH];
		
	sprintf(openbuffer,"./%s/Functions",c_files_name);
	function_dir = opendir(openbuffer);
	if (!function_dir){
		fprintf(stderr,"cannot open directory '%s':", openbuffer);
		perror("opendir");
		exit(1);
	} 
	else if(chdir(openbuffer) == -1){
		fprintf(stderr,"cannot change directory '%s':", openbuffer);
		perror("chdir");
		exit(1);		
	}
	else {
		printf("******* c file %s() *******\n",c_files_name);

		while (function_entry = readdir(function_dir)){
		  	if (function_entry->d_name[0] == '.'){
				continue;
			}			
			if (RunIndividualTests(function_entry->d_name)){
				return 1;
			}

		}
		if (closedir(function_dir) == -1){
			perror("closedir");
		}
		if(chdir("../../") == -1){
			fprintf(stderr,"cannot change directory '%s':", openbuffer);
			perror("chdir");
			exit(1);		
		}
	}
	return 0;
}

int main(void)
{
	struct dirent *c_file_entry;
	DIR *c_files_dir;
	char dirbuffer[MAX_DIR_PATH];
	
	c_files_dir = opendir("./c_files");
	if (!c_files_dir){
		fprintf(stderr,"cannot open directory '%s':", "./c_files");
		perror("opendir");
		exit(1);
	}
	if(chdir("./c_files") == -1){
		fprintf(stderr,"cannot change directory '%s':", "./c_files");
		perror("chdir");
		exit(1);		
	}
	else {
		while (c_file_entry = readdir(c_files_dir)){
		  	if (c_file_entry->d_name[0] == '.'){
				continue;
			}
			if (RecurseFunctions(c_file_entry->d_name)){
				return 1;
			}

		}
		if (closedir(c_files_dir) == -1){
			perror("closedir");
		}
	}
	
	return 0;
}

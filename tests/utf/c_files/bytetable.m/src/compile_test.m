/* The file under test has no main(). I add it here to allow us to link it */
#include "pre.h" // external types declarations, such as u32 or Linux struct bio;

/* actual files to compile test */
#include "../../../../../src/bytetable.h"
#include "../../../../../src/bytetable.m"

/* too lazy to build this junk seperately. */
#include "../../../../../src/compressor.h"
#include "../../../../../src/compressor.m"

int main(int argc, char * argv[])
{
	return 0;
}


#include "header.h"
#include "stubs.h"
#include "CuTest.h"

#include "dir_walker.m"
#include "inodes.m"
#include "btree_object.m"
#include "bytetable.m"
#include "compressible_object.m"
#include "modes.m"
#include "astrings.m"
#include "compressor.m"
#include "region.m"

struct axfs_config acfg;

/****** Test Code ******/

static void DirWalker_createdestroy(CuTest *tc){
	int output;
	DirWalker *dw;
	
	printf("Running %s\n", __FUNCTION__);
	acfg.max_nodes = 100;
	acfg.block_size = 16*1024;
	acfg.page_size = 4096;
	acfg.compression = "lzo";
	acfg.input = "tovfs";

	dw = [[DirWalker alloc] init];
	[dw free];
	[dw release];

	output = 0;
	CuAssertIntEquals(tc, 0, output);
}

/****** End Test Code ******/

static CuSuite* GetSuite(void){
	CuSuite* suite = CuSuiteNew();

	SUITE_ADD_TEST(suite, DirWalker_createdestroy);
	//SUITE_ADD_TEST(suite, );
	return suite;
}

void FreeSuite(CuSuite* suite)
{
	int i;
	for (i = 0 ; i < suite->count ; ++i)
	{
		if(suite->list[i] != NULL) {
			free((void*)suite->list[i]->name);
			free(suite->list[i]);
		} else
			suite->list[i] = 0;
	}
	free(suite);
}

void RunAllTests(void) 
{
	CuString *output = CuStringNew();
	CuSuite* suite = CuSuiteNew();
	CuSuite* newsuite = GetSuite();
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	CuSuiteAddSuite(suite, newsuite);
	CuSuiteRun(suite);
	
	CuSuiteSummary(suite, output);
	CuSuiteDetails(suite, output);
	printf("%s\n", output->buffer);
	FreeSuite(suite);
	free(newsuite);
	free(output->buffer);
	free(output);
	[pool drain];
	return;
}


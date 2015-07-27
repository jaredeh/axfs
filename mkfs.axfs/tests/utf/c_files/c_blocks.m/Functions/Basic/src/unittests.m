#include "header.h"
#include "stubs.h"
#include "CuTest.h"

#include "compressor.m"
#include "c_blocks.m"
#include "compressible_object.m"
#include "hash_object.m"
#include "region.m"
#include "bytetable.m"

struct axfs_config acfg;

/****** Test Code ******/

static void CBlocks_createdestroy(CuTest *tc){
	int output;
	CBlocks *cb;

	printf("Running %s\n", __FUNCTION__);

	acfg.page_size = 4096;
	acfg.block_size = 16*1024;
	acfg.max_nodes = 10;
	acfg.compression = "lzo";
 	cb = [[CBlocks alloc] init];
	[cb free];
	[cb release];

	output = 0;
	CuAssertIntEquals(tc, 0, output);
}

/****** End Test Code ******/

static CuSuite* GetSuite(void){
	CuSuite* suite = CuSuiteNew();

	SUITE_ADD_TEST(suite, CBlocks_createdestroy);
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

	CuSuiteAddSuite(suite, newsuite);
	CuSuiteRun(suite);

	CuSuiteSummary(suite, output);
	CuSuiteDetails(suite, output);
	printf("%s\n", output->buffer);
	FreeSuite(suite);
	free(newsuite);
	free(output->buffer);
	free(output);
	return;
}

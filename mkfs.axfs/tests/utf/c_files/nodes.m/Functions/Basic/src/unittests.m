#include "header.h"
#include "stubs.h"
#include "CuTest.h"

/* Including function under test */
#include "hash_object.m"
#include "bytetable.m"
#include "compressible_object.m"
#include "nodes.m"
#include "pages.m"
#include "compressor.m"
#include "c_blocks.m"
#include "region.m"
#include "xip_nodes.m"
#include "ba_nodes.m"
#include "comp_nodes.m"
#include "nodes_object.m"


/****** Test Code ******/

struct axfs_config acfg;

static void Nodes_createdestroy(CuTest *tc)
{
	Nodes *nodes;
	int output;
	printf("Running %s\n", __FUNCTION__);
	acfg.max_nodes = 100;
	acfg.block_size = 16*1024;
	acfg.page_size = 4096;
	acfg.compression = "lzo";

	nodes = [[Nodes alloc] init];
	[nodes free];
	[nodes release];

	output = 0;
	CuAssertIntEquals(tc, 0, output);
}

/****** End Test Code ******/

static CuSuite* GetSuite(void){
	CuSuite* suite = CuSuiteNew();

	SUITE_ADD_TEST(suite, Nodes_createdestroy);

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

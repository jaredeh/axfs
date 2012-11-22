#include "header.h"
#include "stubs.h"
#include "CuTest.h"

#include "image_builder.m"
#include "dir_walker.m"
#include "inodes.m"
#include "btree_object.m"
#include "compressible_object.m"
#include "paths.m"
#include "modes.m"
#include "astrings.m"
#include "compressor.m"

struct axfs_config acfg;

/****** Test Code ******/

static void ImageBuilder_createdestroy(CuTest *tc){
	int output;
	ImageBuilder *ib;
	
	printf("Running %s\n", __FUNCTION__);

	acfg.max_nodes = 100;
	acfg.block_size = 16*1024;
	acfg.page_size = 4096;
	acfg.compression = "lzo";
	acfg.input = "tovfs";
	ib = [[ImageBuilder alloc] init];
	[ib free];
	[ib release];

	output = 0;
	CuAssertIntEquals(tc, 0, output);
}

/****** End Test Code ******/

static CuSuite* GetSuite(void){
	CuSuite* suite = CuSuiteNew();

	SUITE_ADD_TEST(suite, ImageBuilder_createdestroy);
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


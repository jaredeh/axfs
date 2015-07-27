#include "header.h"
#include "stubs.h"
#include "CuTest.h"

#include "image_builder.m"
#include "dir_walker.m"
#include "inodes.m"
#include "nodes.m"
#include "c_blocks.m"
#include "hash_object.m"
#include "bytetable.m"
#include "compressible_object.m"
#include "modes.m"
#include "astrings.m"
#include "compressor.m"
#include "region.m"
#include "xip_nodes.m"
#include "ba_nodes.m"
#include "comp_nodes.m"
#include "nodes_object.m"
#include "super.m"
#include "pages.m"
#include "region_descriptors.m"


struct axfs_config acfg;
struct axfs_objects aobj;

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
	acfg.max_text_size = 10000;
	acfg.max_number_files = 1000;
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

#include "header.h"
#include "stubs.h"
#include "CuTest.h"

#include "super.h"
#include "super.m"
#include "region.h"
#include "region.m"
#include "bytetable.h"
#include "bytetable.m"
#include "compressor.h"
#include "compressor.m"
#include "nodes.h"
#include "nodes.m"
#include "pages.h"
#include "pages.m"

/****** Test Code ******/

struct axfs_config acfg;

static void Super_createdestroy(CuTest *tc){
	int output;
	Super *sb = [[Super alloc] init];
	
	printf("Running %s\n", __FUNCTION__);

	[sb free];
	[sb release];

	output = 0;
	CuAssertIntEquals(tc, 0, output);
}

static void Super_do_magic(CuTest *tc){
	uint8_t *d;
	Super *sb = [[Super alloc] init];
	
	printf("Running %s\n", __FUNCTION__);

	d = [sb data]; //0x48A0E4CD
	CuAssertHexEquals(tc, 0x48, d[0]);
	CuAssertHexEquals(tc, 0xA0, d[1]);
	CuAssertHexEquals(tc, 0xE4, d[2]);
	CuAssertHexEquals(tc, 0xCD, d[3]);

	[sb free];
	[sb release];
}

static void Super_do_signature(CuTest *tc){
	uint8_t *d;
	Super *sb = [[Super alloc] init];
	
	printf("Running %s\n", __FUNCTION__);

	d = [sb data];
	CuAssertStrEquals(tc, "Advanced XIP FS\0", (char *)(d + 4));

	[sb free];
	[sb release];
}

/****** End Test Code ******/

static CuSuite* GetSuite(void){
	CuSuite* suite = CuSuiteNew();

	SUITE_ADD_TEST(suite, Super_createdestroy);
	SUITE_ADD_TEST(suite, Super_do_magic);
	SUITE_ADD_TEST(suite, Super_do_signature);
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


#include "header.h"
#include "stubs.h"
#include "CuTest.h"

/* Including function under test */
#include "region.h"
#include "region.m"

/****** Test Code ******/

static void Region_createdestroy(CuTest *tc)
{
	int output;

	Region *r;

	printf("Running %s\n", __FUNCTION__);

	r = [[Region alloc] init];
	[r free];
	[r release];

	output = 1;
	CuAssertIntEquals(tc, 0, output);
}

/****** End Test Code ******/


static CuSuite* GetSuite(void){
	CuSuite* suite = CuSuiteNew();

	SUITE_ADD_TEST(suite, Region_createdestroy);
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


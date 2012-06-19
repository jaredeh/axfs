#include "header.h"
#include "stubs.h"
#include "CuTest.h"

#include "compressor.h"
#include "compressor.m"

#include "opts_validator.h"
#include "opts_validator.m"

struct axfs_config acfg;

/****** Test Code ******/

static void OptsValidator_createdestroy(CuTest *tc){
	int output;
	OptsValidator *ov = [[OptsValidator alloc] init];
	
	printf("Running %s\n", __FUNCTION__);

	[ov initialize];
	[ov free];
	[ov release];

	output = 0;
	CuAssertIntEquals(tc, 0, output);
}

/****** End Test Code ******/

static CuSuite* GetSuite(void){
	CuSuite* suite = CuSuiteNew();

	SUITE_ADD_TEST(suite, OptsValidator_createdestroy);
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


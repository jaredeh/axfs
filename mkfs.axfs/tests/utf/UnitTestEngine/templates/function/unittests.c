#include "header.h"
#include "stubs.h"
#include "CuTest.h"

/* Including function under test */
#include "./function.c"

/****** Test Code ******/

static void EXAMPLE__test0(CuTest *tc){
	int input;
	int output;
	
	printf("Running %s\n", __FUNCTION__);
	
	/* Set stimuli for test */
    
	/* Run function under test */
	output = EXAMPLE(...);

	/* check outputs */
	CuAssertIntEquals(tc, 0, output);
	
}

static void EXAMPLE__test1(CuTest *tc){
	int input;
	int output;

	printf("Running %s\n", __FUNCTION__);
	
	/* Set stimuli for test */
    
	/* Run function under test */
	output = EXAMPLE(...);

	/* check outputs */
	CuAssertIntEquals(tc, 0, output);
	
}


/****** End Test Code ******/


static CuSuite* GetSuite(void){
	
	int i;
	
	CuSuite* suite = CuSuiteNew();

	SUITE_ADD_TEST(suite, EXAMPLE__test0);
	SUITE_ADD_TEST(suite, EXAMPLE__test1);

	return suite;
}


void RunAllTests(void) 
{
	CuString *output = CuStringNew();
	CuSuite* suite = CuSuiteNew();
	
	CuSuiteAddSuite(suite, GetSuite());
	CuSuiteRun(suite);
	
	CuSuiteSummary(suite, output);
	CuSuiteDetails(suite, output);
	printf("%s\n", output->buffer);
	return;
}


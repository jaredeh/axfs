#include "header.h"
#include "stubs.h"
#include "CuTest.h"

#include "getopts.h"
#include "getopts.m"

struct axfs_config acfg;

/****** Test Code ******/

static void GetOpts_createdestroy(CuTest *tc){
	int output;
	GetOpts *go = [[GetOpts alloc] init];
	
	printf("Running %s\n", __FUNCTION__);

	[go free];
	[go release];

	output = 0;
	CuAssertIntEquals(tc, 0, output);
}

static void GetOpts_input_1(CuTest *tc){
	int argc = 0;
	char *argv[32];
	GetOpts *go;

	printf("Running %s\n", __FUNCTION__);

	go = [[GetOpts alloc] init];
	acfg.input = 0;
	argc = 2;
	argv[1] = "--input";
	argv[2] = "/foo/bar/";
	[go argc: argc argv: argv];
	[go free];
	[go release];
	CuAssertStrEquals(tc, "/foo/bar/", acfg.input);
	free(acfg.input);
}

static void GetOpts_input_2(CuTest *tc){
	int argc = 0;
	char *argv[32];
	GetOpts *go;

	printf("Running %s\n", __FUNCTION__);

	go = [[GetOpts alloc] init];
	acfg.input = 0;
	argc = 4;
	argv[1] = "--output";
	argv[2] = "jjjjj  ssss";
	argv[3] = "--input";
	argv[4] = "/foo/bar/";
	[go argc: argc argv: argv];
	[go free];
	[go release];
	CuAssertStrEquals(tc, "/foo/bar/", acfg.input);
	free(acfg.input);
}


static void GetOpts_input_3(CuTest *tc){
	int argc = 0;
	char *argv[32];
	GetOpts *go;

	printf("Running %s\n", __FUNCTION__);
	getopt_long(0,NULL,"",NULL,0);

	go = [[GetOpts alloc] init];
	acfg.input = 0;
	argc = 4;
	argv[1] = "--output";
	argv[2] = "jjjjj  ssss";
	argv[3] = "--input";
	argv[4] = "/foo/bar/";
	[go argc: argc argv: argv];
	[go free];
	[go release];
	CuAssertStrEquals(tc, "/foo/bar/", acfg.input);
	free(acfg.input);
}

/*
static void GetOpts_xip_size_1(CuTest *tc){
	int argc = 0;
	char *argv[32];
	GetOpts *go;

	printf("Running %s\n", __FUNCTION__);

	getopt_long(0,NULL,"",NULL,0);

	go = [[GetOpts alloc] init];
	acfg.input = 0;
	argc = 2;
	argv[1] = "--xip_size";
	argv[2] = "32";
	[go argc: argc argv: argv];
	[go free];
	[go release];
	CuAssertIntEquals(tc, 32, acfg.xip_size);
}
*/
/****** End Test Code ******/

static CuSuite* GetSuite(void){
	CuSuite* suite = CuSuiteNew();

	SUITE_ADD_TEST(suite, GetOpts_createdestroy);
//	SUITE_ADD_TEST(suite, GetOpts_xip_size_1);
	SUITE_ADD_TEST(suite, GetOpts_input_1);
	SUITE_ADD_TEST(suite, GetOpts_input_2);
	SUITE_ADD_TEST(suite, GetOpts_input_3);
	//SUITE_ADD_TEST(suite, );
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


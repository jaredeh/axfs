#include "header.h"
#include "stubs.h"
#include "CuTest.h"

/* Including function under test */
#include "compressor.h"
#include "compressor.m"

/****** Test Code ******/

static void Compressor_createdestroy(CuTest *tc)
{
	int output;

	Compressor *c;

	printf("Running %s\n", __FUNCTION__);

	c = [[Compressor alloc] init];
	[c initialize: "gzip"];
	[c free];
	[c release];

	output = 0;
	CuAssertIntEquals(tc, 0, output);
}

static void Compressor_basic_gzip(CuTest *tc)
{
	void* cdata;
	void* data;
	char* d;
	uint64_t csize;
	uint64_t size;
	int i;

	Compressor *c;

	printf("Running %s\n", __FUNCTION__);

	c = [[Compressor alloc] init];
	[c initialize: "gzip"];

	cdata = malloc(4096);
	data = malloc(4096);

	memset(data,0,4096);

	size = 4096;
	csize = 0;
	[c cdata: cdata csize: &csize data: data size: size];

	//printf("size: %i csize: %i\n",(int)size,(int)csize);
	CuAssertTrue(tc, csize != 0);
	CuAssertTrue(tc, csize != 4096);
	CuAssertTrue(tc, csize < 27);

	csize = 0;
	d = data;
	for(i=0;i<3060;i++) {
		d[i] = (char) rand();
	}
	[c cdata: cdata csize: &csize data: data size: size];

	//printf("size: %i csize: %i\n",(int)size,(int)csize);
	CuAssertTrue(tc, csize != 0);
	CuAssertTrue(tc, csize != 4096);
	CuAssertTrue(tc, csize < 3200);
	[c free];
	[c release];

	free(data);
	free(cdata);
}

static void Compressor_basic_lzo(CuTest *tc)
{
	void* cdata;
	void* data;
	char* d;
	uint64_t csize;
	uint64_t size;
	int i;

	Compressor *c;

	printf("Running %s\n", __FUNCTION__);

	c = [[Compressor alloc] init];
	[c initialize: "lzo"];

	cdata = malloc(4096);
	data = malloc(4096);

	memset(data,0,4096);

	size = 4096;
	csize = 0;
	[c cdata: cdata csize: &csize data: data size: size];

	//printf("size: %i csize: %i\n",(int)size,(int)csize);
	CuAssertTrue(tc, csize != 0);
	CuAssertTrue(tc, csize != 4096);
	CuAssertTrue(tc, csize < 28);

	csize = 0;
	d = data;
	for(i=0;i<3060;i++) {
		d[i] = (char) rand();
	}
	[c cdata: cdata csize: &csize data: data size: size];

	//printf("size: %i csize: %i\n",(int)size,(int)csize);
	CuAssertTrue(tc, csize != 0);
	CuAssertTrue(tc, csize != 4096);
	CuAssertTrue(tc, csize < 3100);

	[c free];
	[c release];

	free(data);
	free(cdata);
}

static void Compressor_basic_xz(CuTest *tc)
{
	void* cdata;
	void* data;
	char* d;
	uint64_t csize;
	uint64_t size;
	int i;

	Compressor *c;

	printf("Running %s\n", __FUNCTION__);

	c = [[Compressor alloc] init];
	[c initialize: "xz"];

	cdata = malloc(4096);
	data = malloc(4096);

	memset(data,0,4096);

	size = 4096;
	csize = 0;
	[c cdata: cdata csize: &csize data: data size: size];

	//printf("size: %i csize: %i\n",(int)size,(int)csize);
	CuAssertTrue(tc, csize != 0);
	CuAssertTrue(tc, csize != 4096);
	CuAssertTrue(tc, csize < 93);

	csize = 0;
	d = data;
	for(i=0;i<3060;i++) {
		d[i] = (char) rand();
	}
	[c cdata: cdata csize: &csize data: data size: size];

	//printf("size: %i csize: %i\n",(int)size,(int)csize);
	CuAssertTrue(tc, csize != 0);
	CuAssertTrue(tc, csize != 4096);
	CuAssertTrue(tc, csize < 3200);

	[c free];
	[c release];

	free(data);
	free(cdata);
}

/****** End Test Code ******/


static CuSuite* GetSuite(void){
	CuSuite* suite = CuSuiteNew();

	SUITE_ADD_TEST(suite, Compressor_createdestroy);
	SUITE_ADD_TEST(suite, Compressor_basic_gzip);
	SUITE_ADD_TEST(suite, Compressor_basic_lzo);
//	SUITE_ADD_TEST(suite, Compressor_basic_lzma);
	SUITE_ADD_TEST(suite, Compressor_basic_xz);
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


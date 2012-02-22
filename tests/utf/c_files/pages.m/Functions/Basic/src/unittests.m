#include "header.h"
#include "stubs.h"
#include "CuTest.h"

/* Including function under test */
#include "pages.h"
#include "pages.m"

/****** Test Code ******/

static void PagesComp_less(CuTest *tc){
	int output;
	struct page_struct a;
	struct page_struct b;

	printf("Running %s\n", __FUNCTION__);

	a.data = malloc(4096);
	b.data = malloc(4096);

	memset(a.data,0,4096);
	a.length = 4095;
	memset(b.data,1,4096);
	b.length = 4096;
	output = PagesComp((void *)&a.data,(void *)&b.data);
	CuAssertIntEquals(tc, -1, output);

	memset(a.data,0,4096);
	a.length = 4096;
	memset(b.data,1,4096);
	b.length = 4096;
	output = PagesComp((void *)&a.data,(void *)&b.data);
	CuAssertIntEquals(tc, -1, output);

	memset(a.data,0,4096);
	a.length = 8;
	memset(b.data,1,4096);
	b.length = 8;
	output = PagesComp((void *)&a.data,(void *)&b.data);
	CuAssertIntEquals(tc, -1, output);

	memset(a.data,0,4096);
	a.length = 17;
	memset(b.data,1,4096);
	b.length = 17;
	output = PagesComp((void *)&a.data,(void *)&b.data);
	CuAssertIntEquals(tc, -1, output);

	memset(a.data,0,4096);
	a.length = 7;
	memset(b.data,1,4096);
	b.length = 7;
	output = PagesComp((void *)&a.data,(void *)&b.data);
	CuAssertIntEquals(tc, -1, output);
	free(a.data);
	free(b.data);
}

static void PagesComp_greater(CuTest *tc){
	int output;
	struct page_struct a;
	struct page_struct b;

	printf("Running %s\n", __FUNCTION__);

	a.data = malloc(4096);
	b.data = malloc(4096);

	memset(a.data,1,4096);
	a.length = 4096;
	memset(b.data,0,4096);
	b.length = 4095;
	output = PagesComp((void *)&a.data,(void *)&b.data);
	CuAssertIntEquals(tc, 1, output);

	memset(a.data,1,4096);
	a.length = 4096;
	memset(b.data,0,4096);
	b.length = 4096;
	output = PagesComp((void *)&a.data,(void *)&b.data);
	CuAssertIntEquals(tc, 1, output);

	memset(a.data,1,4096);
	a.length = 8;
	memset(b.data,0,4096);
	b.length = 8;
	output = PagesComp((void *)&a.data,(void *)&b.data);
	CuAssertIntEquals(tc, 1, output);

	memset(a.data,1,4096);
	a.length = 17;
	memset(b.data,0,4096);
	b.length = 17;
	output = PagesComp((void *)&a.data,(void *)&b.data);
	CuAssertIntEquals(tc, 1, output);

	memset(a.data,1,4096);
	a.length = 7;
	memset(b.data,0,4096);
	b.length = 7;
	output = PagesComp((void *)&a.data,(void *)&b.data);
	CuAssertIntEquals(tc, 1, output);
	free(a.data);
	free(b.data);
}

static void PagesComp_equal(CuTest *tc){
	int output;
	struct page_struct a;
	struct page_struct b;

	printf("Running %s\n", __FUNCTION__);

	a.data = malloc(4096);
	b.data = malloc(4096);

	memset(a.data,1,4096);
	a.length = 4096;
	memset(b.data,1,4096);
	b.length = 4096;
	output = PagesComp((void *)&a.data,(void *)&b.data);
	CuAssertIntEquals(tc, 0, output);

	memset(a.data,1,4096);
	a.length = 8;
	memset(b.data,1,4096);
	b.length = 8;
	output = PagesComp((void *)&a.data,(void *)&b.data);
	CuAssertIntEquals(tc, 0, output);

	memset(a.data,1,4096);
	a.length = 17;
	memset(b.data,1,4096);
	b.length = 17;
	output = PagesComp((void *)&a.data,(void *)&b.data);
	CuAssertIntEquals(tc, 0, output);

	memset(a.data,1,4096);
	a.length = 7;
	memset(b.data,1,4096);
	b.length = 7;
	output = PagesComp((void *)&a.data,(void *)&b.data);
	CuAssertIntEquals(tc, 0, output);
	free(a.data);
	free(b.data);
}

static void Pages_createdestroy(CuTest *tc){
	int output;
	Pages *pages = [[Pages alloc] init];
	
	printf("Running %s\n", __FUNCTION__);

	[pages numberPages: 4 path: "./tempfile"];
	[pages free];
	[pages release];

	output = 0;
	CuAssertIntEquals(tc, 0, output);
}

static void Pages_simplesort(CuTest *tc){
	void *output[5];
	uint8_t data0[4096];
	uint8_t data1[4096];
	uint8_t data2[4096];
	uint8_t data3[4096];
	uint8_t data4[4096];
	uint64_t length = 4096;
	int i,j;

	Pages *pages = [[Pages alloc] init];
	[pages numberPages: 4 path: "./tempfile"];

	printf("Running %s\n", __FUNCTION__);

	memset(&data0,5,4096);
	output[0] = [pages addPage: &data0 length: length];

	memset(&data1,6,4096);
	output[1] = [pages addPage: &data1 length: length];

	memset(&data2,7,4096);
	output[2] = [pages addPage: &data2 length: length];

	memset(&data3,4,4096);
	output[3] = [pages addPage: &data3 length: length];

	memset(&data4,5,4096);
	output[4] = [pages addPage: &data4 length: 500];

	CuAssertPtrNotNull(tc, output[0]);
	CuAssertPtrNotNull(tc, output[1]);
	CuAssertPtrNotNull(tc, output[2]);
	CuAssertPtrNotNull(tc, output[3]);
	CuAssertPtrNotNull(tc, output[4]);
	for(i=0; i<5; i++) {
		for(j=0; j<5; j++) {
			if(i == j)
				continue;
			CuAssertTrue(tc, output[i] != output[j]);
		}
	}

	[pages free];
	[pages release];
}

static void Pages_duplicates(CuTest *tc){
	void *output[5];
	uint8_t data0[4096];
	uint8_t data1[4096];
	uint8_t data2[4096];
	uint8_t data3[4096];
	uint8_t data4[4096];
	uint64_t length = 4096;

	Pages *pages = [[Pages alloc] init];
	[pages numberPages: 4 path: "./tempfile"];

	printf("Running %s\n", __FUNCTION__);

	memset(&data0,5,4096);
	output[0] = [pages addPage: &data0 length: length];

	memset(&data1,6,4096);
	output[1] = [pages addPage: &data1 length: length];

	memset(&data2,6,4096);
	output[2] = [pages addPage: &data2 length: length];

	memset(&data3,6,4096);
	output[3] = [pages addPage: &data3 length: length];

	memset(&data4,5,4096);
	output[4] = [pages addPage: &data4 length: length];

	CuAssertPtrNotNull(tc, output[0]);
	CuAssertPtrNotNull(tc, output[1]);
	CuAssertPtrNotNull(tc, output[2]);
	CuAssertPtrNotNull(tc, output[3]);
	CuAssertPtrNotNull(tc, output[4]);
	CuAssertTrue(tc, (output[0] == output[4]));
	CuAssertTrue(tc, (output[1] == output[2]));
	CuAssertTrue(tc, (output[1] == output[3]));

	[pages free];
	[pages release];
}

static void Pages_falsedups(CuTest *tc){
	void *output[5];
	uint8_t data0[4096];
	uint8_t data1[4096];
	uint8_t data2[4096];
	uint8_t data3[4096];
	uint8_t data4[4096];
	uint64_t length = 4096;
	int i,j;

	Pages *pages = [[Pages alloc] init];
	[pages numberPages: 4 path: "./tempfile"];

	printf("Running %s\n", __FUNCTION__);

	memset(&data0,5,4096);
	output[0] = [pages addPage: &data0 length: length];

	memset(&data1,5,4096);
	output[1] = [pages addPage: &data1 length: 4095];

	memset(&data2,5,4096);
	data2[4095] = 6;
	output[2] = [pages addPage: &data2 length: length];

	memset(&data3,5,4096);
	data3[256] = 6;
	output[3] = [pages addPage: &data3 length: length];

	memset(&data4,5,4096);
	data4[0] = 6;
	output[4] = [pages addPage: &data4 length: length];

	CuAssertPtrNotNull(tc, output[0]);
	CuAssertPtrNotNull(tc, output[1]);
	CuAssertPtrNotNull(tc, output[2]);
	CuAssertPtrNotNull(tc, output[3]);
	CuAssertPtrNotNull(tc, output[4]);
	for(i=0; i<5; i++) {
		for(j=0; j<5; j++) {
			if(i == j)
				continue;
			CuAssertTrue(tc, (output[i] != output[j]));
		}
	}

	[pages free];
	[pages release];
}

/****** End Test Code ******/


static CuSuite* GetSuite(void){
	CuSuite* suite = CuSuiteNew();

	SUITE_ADD_TEST(suite, PagesComp_less);
	SUITE_ADD_TEST(suite, PagesComp_greater);
	SUITE_ADD_TEST(suite, PagesComp_equal);
	SUITE_ADD_TEST(suite, Pages_createdestroy);
	SUITE_ADD_TEST(suite, Pages_simplesort);
	SUITE_ADD_TEST(suite, Pages_duplicates);
	SUITE_ADD_TEST(suite, Pages_falsedups);
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


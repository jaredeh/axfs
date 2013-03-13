#include "header.h"
#include "stubs.h"
#include "CuTest.h"

/* Including function under test */
#include "astrings.m"
#include "compressor.m"
#include "compressible_object.m"
#include "btree_object.m"
#include "region.m"

/****** Test Code ******/

struct axfs_config acfg;

static void Strings_createdestroy(CuTest *tc){
	int output;
	Strings *str = [[Strings alloc] init];

	acfg.max_nodes = 100;
	acfg.block_size = 16*1024;
	acfg.page_size = 4096;
	acfg.compression = "lzo";
	acfg.max_text_size = 1000000;
	acfg.max_number_files = 10000;

	printf("Running %s\n", __FUNCTION__);

	[str free];
	[str release];

	output = 0;
	CuAssertIntEquals(tc, 0, output);
}

static void Strings_simplesort(CuTest *tc){
	void *output[5];
	uint8_t data0[4096];
	uint8_t data1[4096];
	uint8_t data2[4096];
	uint8_t data3[4096];
	uint8_t data4[4096];
	uint64_t length = 4096;
	int i,j;

	acfg.max_nodes = 100;
	acfg.block_size = 16*1024;
	acfg.page_size = 4096;
	acfg.compression = "lzo";
	acfg.max_text_size = 1000000;
	acfg.max_number_files = 10000;

	printf("Running %s\n", __FUNCTION__);

	Strings *str = [[Strings alloc] init];

	memset(&data0,'5',4096);
	output[0] = [str addString: &data0 length: length];

	memset(&data1,'6',4096);
	output[1] = [str addString: &data1 length: length];

	memset(&data2,'7',4096);
	output[2] = [str addString: &data2 length: length];

	memset(&data3,'4',4096);
	output[3] = [str addString: &data3 length: length];

	memset(&data4,'5',4096);
	output[4] = [str addString: &data4 length: 500];

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
	[str free];
	[str release];
}

static void Strings_duplicates(CuTest *tc){
	void *output[5];
	uint8_t data0[4096];
	uint8_t data1[4096];
	uint8_t data2[4096];
	uint8_t data3[4096];
	uint8_t data4[4096];
	uint64_t length = 4096;

	acfg.max_nodes = 100;
	acfg.block_size = 16*1024;
	acfg.page_size = 4096;
	acfg.compression = "lzo";
	acfg.max_text_size = 1000000;
	acfg.max_number_files = 10000;

	Strings *str = [[Strings alloc] init];

	printf("Running %s\n", __FUNCTION__);

	memset(&data0,'5',4096);
	output[0] = [str addString: &data0 length: length];

	memset(&data1,'6',4096);
	output[1] = [str addString: &data1 length: length];

	memset(&data2,'6',4096);
	output[2] = [str addString: &data2 length: length];

	memset(&data3,'4',4096);
	output[3] = [str addString: &data3 length: length];

	memset(&data4,'5',4096);
	output[4] = [str addString: &data4 length: 500];

	CuAssertPtrNotNull(tc, output[0]);
	CuAssertPtrNotNull(tc, output[1]);
	CuAssertPtrNotNull(tc, output[2]);
	CuAssertPtrNotNull(tc, output[3]);
	CuAssertPtrNotNull(tc, output[4]);
	CuAssertTrue(tc, (output[1] != output[2]));
	CuAssertTrue(tc, (output[0] != output[4]));

	[str free];
	[str release];
}

static void Strings_falsedups(CuTest *tc){
	void *output[5];
	uint8_t data0[4096];
	uint8_t data1[4096];
	uint8_t data2[4096];
	uint8_t data3[4096];
	uint8_t data4[4096];
	uint64_t length = 4096;
	int i,j;

	acfg.max_nodes = 100;
	acfg.block_size = 16*1024;
	acfg.page_size = 4096;
	acfg.compression = "lzo";
	acfg.max_text_size = 1000000;
	acfg.max_number_files = 10000;

	Strings *str = [[Strings alloc] init];

	printf("Running %s\n", __FUNCTION__);

	memset(&data0,'5',4096);
	output[0] = [str addString: &data0 length: length];

	memset(&data1,'5',4096);
	output[1] = [str addString: &data1 length: 4095];

	memset(&data2,'5',4096);
	data2[4095] = '6';
	output[2] = [str addString: &data2 length: length];

	memset(&data3,'5',4096);
	data3[256] = '6';
	output[3] = [str addString: &data3 length: length];

	memset(&data4,'5',4096);
	data4[0] = '6';
	output[4] = [str addString: &data4 length: 500];

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

	[str free];
	[str release];
}

static void Strings_data(CuTest *tc){
	void *output;
	char *expected;
	char *data;
	uint64_t length;
	int explen = 0;
	void **no;
	acfg.max_text_size = 1000000;
	acfg.max_number_files = 10000;

	acfg.max_nodes = 100;
	acfg.block_size = 16*1024;
	acfg.page_size = 4096;
	acfg.compression = "lzo";

	printf("Running %s\n", __FUNCTION__);

	Strings *str = [[Strings alloc] init];
	no = malloc(5*sizeof(void*));
	memset(no,0,5*sizeof(void*));
	[str nameOrder: no];
	expected = malloc(2000);

	length = 5;
	data = "hello";
	no[0] = [str addString: data length: length];
	memcpy(&expected[explen],data,length);
	explen += length;


	length = 5;
	data = "jared";
	no[1] = [str addString: data length: length];
	memcpy(&expected[explen],data,length);
	explen += length;

	length = 13;
	data = "jared hulbert";
	no[2] = [str addString: data length: length];
	memcpy(&expected[explen],data,length);
	explen += length;

	length = 1000;
	data = malloc(2000);
	memset(data,'a',length);
	no[3] = [str addString: data length: length];
	memcpy(&expected[explen],data,length);
	explen += length;
	free(data);

	expected[explen] = 0;
	output = [str data];
	CuAssertStrEquals(tc, expected, output);
	CuAssertIntEquals(tc, explen, [str size]);
	CuAssertIntEquals(tc, 4, [str length]);
}

static void Strings_cdata(CuTest *tc){
	void *output;
	char *expected;
	char *data;
	uint64_t length;
	int explen = 0;
	void **no;

	acfg.max_nodes = 100;
	acfg.block_size = 16*1024;
	acfg.page_size = 4096;
	acfg.compression = "gzip";
	acfg.max_text_size = 1000000;
	acfg.max_number_files = 10000;

	printf("Running %s\n", __FUNCTION__);

	Strings *str = [[Strings alloc] init];
	no = malloc(5*sizeof(void*));
	memset(no,0,5*sizeof(void*));
	[str nameOrder: no];
	expected = malloc(2000);
    
	length = 5;
	data = "hello";
	no[0] = [str addString: data length: length];
	memcpy(&expected[explen],data,length);
	explen += length;
    
	length = 5;
	data = "jared";
	no[1] = [str addString: data length: length];
	memcpy(&expected[explen],data,length);
	explen += length;
    
	length = 13;
	data = "jared hulbert";
	no[2] = [str addString: data length: length];
	memcpy(&expected[explen],data,length);
	explen += length;
    
	length = 1000;
	data = malloc(2000);
	memset(data,'a',length);
	no[3] = [str addString: data length: length];
	memcpy(&expected[explen],data,length);
	explen += length;
	free(data);
    
	expected[explen] = 0;
	output = [str cdata];
	CuAssertTrue(tc, (expected[2] != ((char *)output)[2]));
	CuAssertIntEquals(tc, 35, [str csize]);
	CuAssertIntEquals(tc, 4, [str length]);
}

/****** End Test Code ******/


static CuSuite* GetSuite(void){
	CuSuite* suite = CuSuiteNew();

	SUITE_ADD_TEST(suite, Strings_createdestroy);
	SUITE_ADD_TEST(suite, Strings_simplesort);
	SUITE_ADD_TEST(suite, Strings_duplicates);
	SUITE_ADD_TEST(suite, Strings_falsedups);
	SUITE_ADD_TEST(suite, Strings_data);
	SUITE_ADD_TEST(suite, Strings_cdata);
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


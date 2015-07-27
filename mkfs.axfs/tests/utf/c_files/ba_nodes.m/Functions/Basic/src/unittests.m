#include "header.h"
#include "stubs.h"
#include "CuTest.h"

/* Including function under test */
#include "hash_object.m"
#include "bytetable.m"
#include "compressible_object.m"
#include "pages.m"
#include "compressor.m"
#include "c_blocks.m"
#include "region.m"
#include "ba_nodes.m"
#include "nodes_object.m"


/****** Test Code ******/

struct axfs_config acfg;

static void BaNodes_createdestroy(CuTest *tc)
{
	BaNodes *nodes;
	int output;
	printf("Running %s\n", __FUNCTION__);
	acfg.max_nodes = 100;
	acfg.block_size = 16*1024;
	acfg.page_size = 4096;
	acfg.compression = "lzo";

	nodes = [[BaNodes alloc] init];
	[nodes free];
	[nodes release];

	output = 0;
	CuAssertIntEquals(tc, 0, output);
}

static void BaNodes_size_bytealigned(CuTest *tc)
{
	BaNodes *nodes;
	Pages *pages;
	uint64_t l, r = 0;
	uint8_t *data0;
	uint8_t *data1;
	uint8_t *data2;
	uint8_t *data3;
	uint8_t *data4;
	void *output[5];
	uint8_t *compare;
	uint64_t length;
	uint64_t size;
	void *data;

	printf("Running %s\n", __FUNCTION__);
	acfg.page_size = 4096;
	acfg.max_nodes = 10;

	nodes = [[BaNodes alloc] init];

	pages = [[Pages alloc] init];

	l = 5;
	r += l;
	data0 = malloc(l);
	memset(data0,5,l);
	output[0] = [pages addPage: data0 length: l];
	l = 17;
	r += l;
	data1 = malloc(l);
	memset(data1,6,l);
	output[1] = [pages addPage: data1 length: l];
	l = 29;
	r += l;
	data2 = malloc(l);
	memset(data2,7,l);
	output[2] = [pages addPage: data2 length: l];
	l = 21;
	r += l;
	data3 = malloc(l);
	memset(data3,4,l);
	output[3] = [pages addPage: data3 length: l];
	l = 14;
	r += l;
	data4 = malloc(l);
	memset(data4,5,l);
	output[4] = [pages addPage: data4 length: l];

	[nodes addPage: output[0]];
	[nodes addPage: output[1]];
	[nodes addPage: output[2]];
	[nodes addPage: output[3]];
	[nodes addPage: output[4]];

	length = [nodes length];
	size = [nodes size];
	CuAssertIntEquals(tc, 5, length);
	CuAssertIntEquals(tc, r, size);
	compare = malloc(size);
	memset(compare,0,size);
	memcpy(compare,data0,5);
	memcpy(compare+5,data1,17);
	memcpy(compare+17+5,data2,29);
	memcpy(compare+29+17+5,data3,21);
	memcpy(compare+21+29+17+5,data4,14);
	data = [nodes data];
	CuAssertBufEquals(tc, compare, data, size);

	[nodes free];
	[nodes release];
	[pages free];
	[pages release];
}


void print_data(void *d, uint64_t l)
{
	int i;
	uint8_t *c = d;

	for(i=0;i<l;i++) {
		printf("%02x",c[i]);
	}
	printf("\n");
}
/**/

static void BaNodes_size_ba_cdata(CuTest *tc)
{
	BaNodes *nodes;
	Pages *pages;
	uint64_t l, r = 0;
	uint8_t *data0;
	uint8_t *data1;
	uint8_t *data2;
	uint8_t *data3;
	uint8_t *data4;
	void *output[5];
	uint8_t *compare;
	uint64_t length;
	uint64_t size, csize;
	void *data, *cdata;

	printf("Running %s\n", __FUNCTION__);
	acfg.page_size = 4096;
	acfg.max_nodes = 10;

	nodes = [[BaNodes alloc] init];

	pages = [[Pages alloc] init];

	l = 5;
	r += l;
	data0 = malloc(l);
	memset(data0,5,l);
	output[0] = [pages addPage: data0 length: l];
	l = 17;
	r += l;
	data1 = malloc(l);
	memset(data1,6,l);
	output[1] = [pages addPage: data1 length: l];
	l = 29;
	r += l;
	data2 = malloc(l);
	memset(data2,7,l);
	output[2] = [pages addPage: data2 length: l];
	l = 21;
	r += l;
	data3 = malloc(l);
	memset(data3,4,l);
	output[3] = [pages addPage: data3 length: l];
	l = 14;
	r += l;
	data4 = malloc(l);
	memset(data4,5,l);
	output[4] = [pages addPage: data4 length: l];

	[nodes addPage: output[0]];
	[nodes addPage: output[1]];
	[nodes addPage: output[2]];
	[nodes addPage: output[3]];
	[nodes addPage: output[4]];

	length = [nodes length];
	size = [nodes size];
	CuAssertIntEquals(tc, 5, length);

	CuAssertIntEquals(tc, r, size);

	compare = malloc(size);
	memset(compare,0,size);

	memcpy(compare,data0,5);
	memcpy(compare+5,data1,17);
	memcpy(compare+17+5,data2,29);
	memcpy(compare+29+17+5,data3,21);
	memcpy(compare+21+29+17+5,data4,14);

	data = [nodes data];

	CuAssertBufEquals(tc, compare, data, size);

	cdata = [nodes cdata];
	csize = [nodes csize];

	CuAssertTrue(tc, csize <= size);
	CuAssertTrue(tc, csize > 0);
	CuAssertTrue(tc, cdata != 0);

	[nodes free];
	[nodes release];
	[pages free];
	[pages release];
}

/****** End Test Code ******/

static CuSuite* GetSuite(void){
	CuSuite* suite = CuSuiteNew();

	SUITE_ADD_TEST(suite, BaNodes_createdestroy);
	SUITE_ADD_TEST(suite, BaNodes_size_bytealigned);
	SUITE_ADD_TEST(suite, BaNodes_size_ba_cdata);
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

#include "header.h"
#include "stubs.h"
#include "CuTest.h"

/* Including function under test */
#include "btree_object.m"
#include "compressible_object.m"
#include "nodes.m"
#include "pages.m"
#include "compressor.m"
#include "c_blocks.m"

/****** Test Code ******/

struct axfs_config acfg;

static void Nodes_createdestroy(CuTest *tc)
{
	Nodes *nodes;
	int output;
	printf("Running %s\n", __FUNCTION__);
	acfg.max_nodes = 100;
	acfg.block_size = 16*1024;
	acfg.page_size = 4096;
	acfg.compression = "lzo";

	nodes = [[Nodes alloc] init];
	[nodes setType: TYPE_XIP];
	[nodes free];
	[nodes release];

	nodes = [[Nodes alloc] init];
	[nodes setType: TYPE_BYTEALIGNED];
	[nodes free];
	[nodes release];

	nodes = [[Nodes alloc] init];
	[nodes setType: TYPE_COMPRESS];
	[nodes free];
	[nodes release];

	output = 0;
	CuAssertIntEquals(tc, 0, output);
}

static void Nodes_size_xip4k(CuTest *tc)
{
	Nodes *nodes;
	Pages *pages;
	uint64_t l = 4 * 1024;
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
	acfg.page_size = l;
	acfg.max_nodes = 10;
	
	nodes = [[Nodes alloc] init];
	[nodes setType: TYPE_XIP];

	pages = [[Pages alloc] init];

	data0 = malloc(l);
	memset(data0,5,l);
	output[0] = [pages addPage: data0 length: l];

	data1 = malloc(l);
	memset(data1,6,l);
	output[1] = [pages addPage: data1 length: l];

	data2 = malloc(l);
	memset(data2,7,l);
	output[2] = [pages addPage: data2 length: l];

	data3 = malloc(l);
	memset(data3,4,l);
	output[3] = [pages addPage: data3 length: 4000];

	data4 = malloc(l);
	memset(data4,5,l);
	output[4] = [pages addPage: data4 length: 500];

	[nodes addPage: output[0]];
	[nodes addPage: output[1]];
	[nodes addPage: output[2]];
	[nodes addPage: output[3]];
	[nodes addPage: output[4]];

	length = [nodes length];
    size = [nodes size];
 	CuAssertIntEquals(tc, 5, length);
	CuAssertIntEquals(tc, 4096*5, size);
	compare = malloc(size);
	memset(compare,0,size);
	memcpy(compare,data0,l);
	memcpy(compare+l,data1,l);
	memcpy(compare+(2*l),data2,l);
	memcpy(compare+(3*l),data3,4000);
	memcpy(compare+(4*l),data4,500);
	data = [nodes data];
	CuAssertBufEquals(tc, compare, data, size);

	[nodes free];
	[nodes release];
	[pages free];
	[pages release];
}

static void Nodes_size_xip64k(CuTest *tc)
{
	Nodes *nodes;
	Pages *pages;
	uint64_t l = 64 * 1024;
	uint8_t data0[l];
	uint8_t data1[l];
	uint8_t data2[l];
	uint8_t data3[l];
	uint8_t data4[l];
	void *output[5];
	uint8_t *compare;
	uint64_t length, size;
	void * data;

	printf("Running %s\n", __FUNCTION__);
	acfg.page_size = l;
	acfg.max_nodes = 10;
	nodes = [[Nodes alloc] init];
	[nodes setType: TYPE_XIP];

	pages = [[Pages alloc] init];

	memset(&data0,5,l);
	output[0] = [pages addPage: &data0 length: l];

	memset(&data1,6,l);
	output[1] = [pages addPage: &data1 length: l];

	memset(&data2,7,l);
	output[2] = [pages addPage: &data2 length: l];

	memset(&data3,4,l);
	output[3] = [pages addPage: &data3 length: 4000];

	memset(&data4,5,l);
	output[4] = [pages addPage: &data4 length: 500];

	[nodes addPage: output[0]];
	[nodes addPage: output[1]];
	[nodes addPage: output[2]];
	[nodes addPage: output[3]];
	[nodes addPage: output[4]];

	length = [nodes length];
	size = [nodes size];

	CuAssertIntEquals(tc, 5, length);
	CuAssertIntEquals(tc, 64*1024*5, size);
	compare = malloc(size);
	memcpy(compare,&data0,l);
	memcpy(compare+l,&data1,l);
	memcpy(compare+(2*l),&data2,l);
	memcpy(compare+(3*l),&data3,4000);
	memcpy(compare+(4*l),&data4,500);
	data = [nodes data];
	CuAssertBufEquals(tc, compare, data, size);

	[nodes free];
	[nodes release];
	[pages free];
	[pages release];
}

static void Nodes_xip_cdata(CuTest *tc)
{
	Nodes *nodes;
	Pages *pages;
	uint64_t l = 4 * 1024;
	uint8_t data0[l];
	uint8_t data1[l];
	uint8_t data2[l];
	uint8_t data3[l];
	uint8_t data4[l];
	void *output[5];
	uint8_t *compare;
	uint64_t length, size, csize;
	void *data, *cdata;

	printf("Running %s\n", __FUNCTION__);
	acfg.page_size = l;
	acfg.max_nodes = 10;
	acfg.compression = "lzo";

	nodes = [[Nodes alloc] init];
	[nodes setType: TYPE_XIP];
	pages = [[Pages alloc] init];

	memset(&data0,5,l);
	output[0] = [pages addPage: &data0 length: l];

	memset(&data1,6,l);
	output[1] = [pages addPage: &data1 length: l];

	memset(&data2,7,l);
	output[2] = [pages addPage: &data2 length: l];

	memset(&data3,4,l);
	output[3] = [pages addPage: &data3 length: 4000];

	memset(&data4,5,l);
	output[4] = [pages addPage: &data4 length: 500];

	[nodes addPage: output[0]];
	[nodes addPage: output[1]];
	[nodes addPage: output[2]];
	[nodes addPage: output[3]];
	[nodes addPage: output[4]];
	length = [nodes length];
    size = [nodes size];
 
	CuAssertIntEquals(tc, 5, length);
	CuAssertIntEquals(tc, 4096*5, size);
	compare = malloc(size);

	memset(compare,0,size);
	memcpy(compare,data0,l);
	memcpy(compare+l,data1,l);
	memcpy(compare+(2*l),data2,l);
	memcpy(compare+(3*l),data3,4000);
	memcpy(compare+(4*l),data4,500);


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

static void Nodes_size_bytealigned(CuTest *tc)
{
	Nodes *nodes;
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
	
	nodes = [[Nodes alloc] init];
	[nodes setType: TYPE_BYTEALIGNED];

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

static void Nodes_size_ba_cdata(CuTest *tc)
{
	Nodes *nodes;
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
	
	nodes = [[Nodes alloc] init];
	[nodes setType: TYPE_BYTEALIGNED];

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

static void Nodes_compressed_little(CuTest *tc)
{
	Nodes *nodes;
	Pages *pages;
	uint64_t l = 4 * 1024;
	uint8_t *data0;
	uint8_t *data1;
	uint8_t *data2;
	uint8_t *data3;
	uint8_t *data4;
	void *output[5];
	uint64_t length;
	uint64_t size;
	void *data;

	printf("Running %s\n", __FUNCTION__);
	acfg.max_nodes = 1000;
	acfg.block_size = 16*1024;
	acfg.page_size = 4096;
	acfg.compression = "lzo";

	nodes = [[Nodes alloc] init];
	[nodes setType: TYPE_COMPRESS];
	pages = [[Pages alloc] init];

	data0 = malloc(l);
	memset(data0,5,l);
	output[0] = [pages addPage: data0 length: l];

	data1 = malloc(l);
	memset(data1,6,l);
	output[1] = [pages addPage: data1 length: l];

	data2 = malloc(l);
	memset(data2,7,l);
	output[2] = [pages addPage: data2 length: l];

	data3 = malloc(l);
	memset(data3,4,l);
	output[3] = [pages addPage: data3 length: 4000];

	data4 = malloc(l);
	memset(data4,5,l);
	output[4] = [pages addPage: data4 length: 500];

	[nodes addPage: output[0]];
	[nodes addPage: output[1]];
	[nodes addPage: output[2]];
	[nodes addPage: output[3]];
	[nodes addPage: output[4]];

	length = [nodes length];
    size = [nodes size];
 	CuAssertIntEquals(tc, 5, length);
	data = [nodes data];
	CuAssertTrue(tc, 4096*5 > size);
	CuAssertTrue(tc, 0 < size);
	CuAssertTrue(tc, data != 0);

	[nodes free];
	[nodes release];
	[pages free];
	[pages release];
}

/****** End Test Code ******/

static CuSuite* GetSuite(void){
	CuSuite* suite = CuSuiteNew();

	SUITE_ADD_TEST(suite, Nodes_createdestroy);
	SUITE_ADD_TEST(suite, Nodes_size_xip4k);
	SUITE_ADD_TEST(suite, Nodes_size_xip64k);
	SUITE_ADD_TEST(suite, Nodes_xip_cdata);
	SUITE_ADD_TEST(suite, Nodes_size_bytealigned);
	SUITE_ADD_TEST(suite, Nodes_size_ba_cdata);
	SUITE_ADD_TEST(suite, Nodes_compressed_little);
//	SUITE_ADD_TEST(suite, Nodes_compressed_big);
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


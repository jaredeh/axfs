#include "header.h"
#include "stubs.h"
#include "CuTest.h"

/* Including function under test */
#include "region.h"
#include "region.m"
#include "bytetable.h"
#include "bytetable.m"
#include "nodes.h"
#include "nodes.m"
#include "compressor.h"
#include "compressor.m"
#include "pages.h"
#include "pages.m"
/****** Test Code ******/

static void Region_createdestroy(CuTest *tc)
{
	int output;

	Region *r;

	printf("Running %s\n", __FUNCTION__);

	r = [[Region alloc] init];
	[r free];
	[r release];

	output = 0;
	CuAssertIntEquals(tc, 0, output);
}

static void Region_big_endian_number(CuTest *tc)
{
	uint64_t number;
	uint8_t *output;
	int i;

	Region *r;
	ByteTable *bt;

	printf("Running %s\n", __FUNCTION__);

	bt = [[ByteTable alloc] init];
	r = [[Region alloc] init];
	[r initialize];

	[bt numberEntries: 4096 dedup: false];
	
	[bt add: 0x123456];
	[bt add: 0x0];
	for(i=0; i<4096; i++) {
		[bt add: 0x789AB0 + i];
	}

	[r addBytetable: bt];

	number = 0x0102030405060708UL;
	[r big_endian_64: number];
	output = [r data_p];
	CuAssertHexEquals(tc, 0x01, output[0]);
	CuAssertHexEquals(tc, 0x02, output[1]);
	CuAssertHexEquals(tc, 0x03, output[2]);
	CuAssertHexEquals(tc, 0x04, output[3]);
	CuAssertHexEquals(tc, 0x05, output[4]);
	CuAssertHexEquals(tc, 0x06, output[5]);
	CuAssertHexEquals(tc, 0x07, output[6]);
	CuAssertHexEquals(tc, 0x08, output[7]);
	number = 0x090a0b0c0d0e0f10UL;
	[r big_endian_64: number];
	output = [r data_p];
	CuAssertHexEquals(tc, 0x09, output[8]);
	CuAssertHexEquals(tc, 0x0a, output[9]);
	CuAssertHexEquals(tc, 0x0b, output[10]);
	CuAssertHexEquals(tc, 0x0c, output[11]);
	CuAssertHexEquals(tc, 0x0d, output[12]);
	CuAssertHexEquals(tc, 0x0e, output[13]);
	CuAssertHexEquals(tc, 0x0f, output[14]);
	CuAssertHexEquals(tc, 0x10, output[15]);
	number = 0x1112131415161718UL;
	[r big_endian_64: number];
	output = [r data_p];
	CuAssertHexEquals(tc, 0x11, output[16]);
	CuAssertHexEquals(tc, 0x12, output[17]);
	CuAssertHexEquals(tc, 0x13, output[18]);
	CuAssertHexEquals(tc, 0x14, output[19]);
	CuAssertHexEquals(tc, 0x15, output[20]);
	CuAssertHexEquals(tc, 0x16, output[21]);
	CuAssertHexEquals(tc, 0x17, output[22]);
	CuAssertHexEquals(tc, 0x18, output[23]);

	[r free];
	[r release];
	[bt free];
	[bt release];
}

static void Region_bytetable_data(CuTest *tc)
{
	uint8_t *output;
	int i;

	Region *r;
	ByteTable *bt;

	printf("Running %s\n", __FUNCTION__);

	bt = [[ByteTable alloc] init];
	r = [[Region alloc] init];
	[r initialize];

	[bt numberEntries: 5000 dedup: false];
	
	[bt add: 0x123456];
	[bt add: 0x0];
	for(i=0; i<4096; i++) {
		[bt add: 0x000000 + i];
	}

	[r addBytetable: bt];

	[r fsoffset: 0x4455667711223388UL];
	[r incore: 1];
	output = [r data];

	CuAssertHexEquals(tc, 0x44, output[0]);
	CuAssertHexEquals(tc, 0x55, output[1]);
	CuAssertHexEquals(tc, 0x66, output[2]);
	CuAssertHexEquals(tc, 0x77, output[3]);
	CuAssertHexEquals(tc, 0x11, output[4]);
	CuAssertHexEquals(tc, 0x22, output[5]);
	CuAssertHexEquals(tc, 0x33, output[6]);
	CuAssertHexEquals(tc, 0x88, output[7]);
	CuAssertHexEquals(tc, 0x00, output[8]);
	CuAssertHexEquals(tc, 0x00, output[9]);
	CuAssertHexEquals(tc, 0x00, output[10]);
	CuAssertHexEquals(tc, 0x00, output[11]);
	CuAssertHexEquals(tc, 0x00, output[12]);
	CuAssertHexEquals(tc, 0x00, output[13]);
	CuAssertHexEquals(tc, 0x30, output[14]);
	CuAssertHexEquals(tc, 0x06, output[15]);
	CuAssertHexEquals(tc, 0x00, output[16]);
	CuAssertHexEquals(tc, 0x00, output[17]);
	CuAssertHexEquals(tc, 0x00, output[18]);
	CuAssertHexEquals(tc, 0x00, output[19]);
	CuAssertHexEquals(tc, 0x00, output[20]);
	CuAssertHexEquals(tc, 0x00, output[21]);
	CuAssertHexEquals(tc, 0x20, output[22]);
	CuAssertHexEquals(tc, 0xf3, output[23]);
	CuAssertHexEquals(tc, 0x00, output[24]);
	CuAssertHexEquals(tc, 0x00, output[25]);
	CuAssertHexEquals(tc, 0x00, output[26]);
	CuAssertHexEquals(tc, 0x00, output[27]);
	CuAssertHexEquals(tc, 0x00, output[28]);
	CuAssertHexEquals(tc, 0x00, output[29]);
	CuAssertHexEquals(tc, 0x10, output[30]);
	CuAssertHexEquals(tc, 0x02, output[31]);
	CuAssertHexEquals(tc, 0x03, output[32]);
	CuAssertHexEquals(tc, 0x01, output[33]);

	[r free];
	[r release];

	[bt free];
	[bt release];
}

static void get_nodes_cdata(Nodes **nd, Pages **pg, uint8_t *d)
{
	Nodes *nodes = *nd;
	Pages *pages = *pg;
	uint64_t l = 4 * 1024;
	uint8_t *data0 = d;
	uint8_t *data1 = d + l;
	uint8_t *data2 = d + l*2;
	uint8_t *data3 = d + l*3;
	uint8_t *data4 = d + l*4;
	uint8_t *data5 = d + l*5;
	void *output[9];

	[nodes pageSize: l];
	[nodes numberEntries: 4096 nodeType: TYPE_XIP];

	[pages numberPages: 100 path: "./tempfile"];


	memset(data0,5,l);
	output[0] = [pages addPage: data0 length: l];

	memset(data1,2,l);
	output[1] = [pages addPage: data1 length: l];

	memset(data2,6,l);
	output[2] = [pages addPage: data2 length: l];

	memset(data3,7,l);
	output[3] = [pages addPage: data3 length: l];

	memset(data4,4,l);
	output[4] = [pages addPage: data4 length: 4000];

	memset(data5,5,l);
	output[5] = [pages addPage: data5 length: 500];

	[nodes addPage: output[0]];
	[nodes addPage: output[2]];
	[nodes addPage: output[3]];
	[nodes addPage: output[4]];
	[nodes addPage: output[5]];
}

static void Region_nodes_data(CuTest *tc)
{
	uint8_t *output;
	uint64_t l = 4 * 1024;
	uint8_t *d;

	Region *r;
	Nodes *nd;
	Pages *pg;

	printf("Running %s\n", __FUNCTION__);

	nd = [[Nodes alloc] init];
	pg = [[Pages alloc] init];
	r = [[Region alloc] init];
	[r initialize];

	d = malloc(l*7);
	get_nodes_cdata(&nd, &pg, d);
	[r addNodes: nd];

	[r fsoffset: 0x4455667711223399UL];
	[r incore: 1];
	output = [r data];

	CuAssertHexEquals(tc, 0x44, output[0]);
	CuAssertHexEquals(tc, 0x55, output[1]);
	CuAssertHexEquals(tc, 0x66, output[2]);
	CuAssertHexEquals(tc, 0x77, output[3]);
	CuAssertHexEquals(tc, 0x11, output[4]);
	CuAssertHexEquals(tc, 0x22, output[5]);
	CuAssertHexEquals(tc, 0x33, output[6]);
	CuAssertHexEquals(tc, 0x99, output[7]);
	CuAssertHexEquals(tc, 0x00, output[8]);
	CuAssertHexEquals(tc, 0x00, output[9]);
	CuAssertHexEquals(tc, 0x00, output[10]);
	CuAssertHexEquals(tc, 0x00, output[11]);
	CuAssertHexEquals(tc, 0x00, output[12]);
	CuAssertHexEquals(tc, 0x00, output[13]);
	CuAssertHexEquals(tc, 0x50, output[14]);
	CuAssertHexEquals(tc, 0x00, output[15]);
	CuAssertHexEquals(tc, 0x00, output[16]);
	CuAssertHexEquals(tc, 0x00, output[17]);
	CuAssertHexEquals(tc, 0x00, output[18]);
	CuAssertHexEquals(tc, 0x00, output[19]);
	CuAssertHexEquals(tc, 0x00, output[20]);
	CuAssertHexEquals(tc, 0x00, output[21]);
	CuAssertHexEquals(tc, 0x00, output[22]);
	CuAssertHexEquals(tc, 0x7f, output[23]);
	CuAssertHexEquals(tc, 0x00, output[24]);
	CuAssertHexEquals(tc, 0x00, output[25]);
	CuAssertHexEquals(tc, 0x00, output[26]);
	CuAssertHexEquals(tc, 0x00, output[27]);
	CuAssertHexEquals(tc, 0x00, output[28]);
	CuAssertHexEquals(tc, 0x00, output[29]);
	CuAssertHexEquals(tc, 0x00, output[30]);
	CuAssertHexEquals(tc, 0x05, output[31]);
	CuAssertHexEquals(tc, 0x00, output[32]);
	CuAssertHexEquals(tc, 0x01, output[33]);

	[r free];
	[r release];
	[nd free];
	[nd release];
	[pg free];
	[pg release];
	free(d);
}

/****** End Test Code ******/


static CuSuite* GetSuite(void){
	CuSuite* suite = CuSuiteNew();

	SUITE_ADD_TEST(suite, Region_createdestroy);
	SUITE_ADD_TEST(suite, Region_big_endian_number);
	SUITE_ADD_TEST(suite, Region_bytetable_data);
	SUITE_ADD_TEST(suite, Region_nodes_data);
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


#include "header.h"
#include "stubs.h"
#include "CuTest.h"

/* Including function under test */
#include "region.m"
#include "bytetable.m"
#include "nodes_object.m"
#include "nodes.m"
#include "ba_nodes.m"
#include "xip_nodes.m"
#include "comp_nodes.m"
#include "compressor.m"
#include "pages.m"
#include "c_blocks.m"
#include "compressible_object.m"
#include "hash_object.m"
#include "axfs_helper.m"

/****** Test Code ******/

struct axfs_config acfg;

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

static void Region_bytetable_data(CuTest *tc)
{
	uint8_t *output;
	int i;

	Region *r;
	ByteTable *bt;

	printf("Running %s\n", __FUNCTION__);
	acfg.max_nodes = 100;
	acfg.block_size = 16*1024;
	acfg.page_size = 4096;
	acfg.compression = "lzo";
	acfg.max_number_files = 100;

	bt = [[ByteTable alloc] init];
	r = [[Region alloc] init];

	[bt numberEntries: 5000 dedup: false];

	[bt add: 0x123456];
	[bt add: 0x0];
	for(i=0; i<4096; i++) {
		[bt add: 0x000000 + i];
	}

	[r add: bt];
	[bt fsoffset: 0x4455667711223388UL];
	[r incore: 1];
	output = [r data];

//	u64 fsoffset;
	CuAssertHexEquals(tc, 0x44, output[0]);
	CuAssertHexEquals(tc, 0x55, output[1]);
	CuAssertHexEquals(tc, 0x66, output[2]);
	CuAssertHexEquals(tc, 0x77, output[3]);
	CuAssertHexEquals(tc, 0x11, output[4]);
	CuAssertHexEquals(tc, 0x22, output[5]);
	CuAssertHexEquals(tc, 0x33, output[6]);
	CuAssertHexEquals(tc, 0x88, output[7]);
//	u64 size;
	CuAssertHexEquals(tc, 0x00, output[8]);
	CuAssertHexEquals(tc, 0x00, output[9]);
	CuAssertHexEquals(tc, 0x00, output[10]);
	CuAssertHexEquals(tc, 0x00, output[11]);
	CuAssertHexEquals(tc, 0x00, output[12]);
	CuAssertHexEquals(tc, 0x00, output[13]);
	CuAssertHexEquals(tc, 0x30, output[14]);
	CuAssertHexEquals(tc, 0x06, output[15]);
//	u64 compressed_size;
	CuAssertHexEquals(tc, 0x00, output[16]);
	CuAssertHexEquals(tc, 0x00, output[17]);
	CuAssertHexEquals(tc, 0x00, output[18]);
	CuAssertHexEquals(tc, 0x00, output[19]);
	CuAssertHexEquals(tc, 0x00, output[20]);
	CuAssertHexEquals(tc, 0x00, output[21]);
	CuAssertHexEquals(tc, 0x30, output[22]);
	CuAssertHexEquals(tc, 0x00, output[23]);
//	u64 max_index;
	CuAssertHexEquals(tc, 0x00, output[24]);
	CuAssertHexEquals(tc, 0x00, output[25]);
	CuAssertHexEquals(tc, 0x00, output[26]);
	CuAssertHexEquals(tc, 0x00, output[27]);
	CuAssertHexEquals(tc, 0x00, output[28]);
	CuAssertHexEquals(tc, 0x00, output[29]);
	CuAssertHexEquals(tc, 0x10, output[30]);
	CuAssertHexEquals(tc, 0x02, output[31]);
//	u8 table_byte_depth;
	CuAssertHexEquals(tc, 0x03, output[32]);
//	u8 incore;
	CuAssertHexEquals(tc, 0x01, output[33]);

	[r free];
	[r release];

	[bt free];
	[bt release];
}

static void Region_bytetable_data_notcore(CuTest *tc)
{
	uint8_t *output;
	int i;

	Region *r;
	ByteTable *bt;

	printf("Running %s\n", __FUNCTION__);
	acfg.max_nodes = 100;
	acfg.block_size = 16*1024;
	acfg.page_size = 4096;
	acfg.compression = "lzo";
	acfg.max_number_files = 100;

	bt = [[ByteTable alloc] init];
	r = [[Region alloc] init];

	[bt numberEntries: 5000 dedup: false];

	[bt add: 0x123456];
	[bt add: 0x0];
	for(i=0; i<4096; i++) {
		[bt add: 0x000000 + i];
	}

	[r add: bt];
	[bt fsoffset: 0x4455667711223388UL];
	[r incore: 0];
	output = [r data];

//	u64 fsoffset;
	CuAssertHexEquals(tc, 0x44, output[0]);
	CuAssertHexEquals(tc, 0x55, output[1]);
	CuAssertHexEquals(tc, 0x66, output[2]);
	CuAssertHexEquals(tc, 0x77, output[3]);
	CuAssertHexEquals(tc, 0x11, output[4]);
	CuAssertHexEquals(tc, 0x22, output[5]);
	CuAssertHexEquals(tc, 0x33, output[6]);
	CuAssertHexEquals(tc, 0x88, output[7]);
//	u64 size;
	CuAssertHexEquals(tc, 0x00, output[8]);
	CuAssertHexEquals(tc, 0x00, output[9]);
	CuAssertHexEquals(tc, 0x00, output[10]);
	CuAssertHexEquals(tc, 0x00, output[11]);
	CuAssertHexEquals(tc, 0x00, output[12]);
	CuAssertHexEquals(tc, 0x00, output[13]);
	CuAssertHexEquals(tc, 0x30, output[14]);
	CuAssertHexEquals(tc, 0x06, output[15]);
//	u64 compressed_size;
	CuAssertHexEquals(tc, 0x00, output[16]);
	CuAssertHexEquals(tc, 0x00, output[17]);
	CuAssertHexEquals(tc, 0x00, output[18]);
	CuAssertHexEquals(tc, 0x00, output[19]);
	CuAssertHexEquals(tc, 0x00, output[20]);
	CuAssertHexEquals(tc, 0x00, output[21]);
	CuAssertHexEquals(tc, 0x30, output[22]);
	CuAssertHexEquals(tc, 0x00, output[23]);
//	u64 max_index;
	CuAssertHexEquals(tc, 0x00, output[24]);
	CuAssertHexEquals(tc, 0x00, output[25]);
	CuAssertHexEquals(tc, 0x00, output[26]);
	CuAssertHexEquals(tc, 0x00, output[27]);
	CuAssertHexEquals(tc, 0x00, output[28]);
	CuAssertHexEquals(tc, 0x00, output[29]);
	CuAssertHexEquals(tc, 0x10, output[30]);
	CuAssertHexEquals(tc, 0x02, output[31]);
//	u8 table_byte_depth;
	CuAssertHexEquals(tc, 0x03, output[32]);
//	u8 incore;
	CuAssertHexEquals(tc, 0x00, output[33]);

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

	acfg.page_size = l;
	acfg.max_nodes = 10;
	acfg.compression = "lzo";
	acfg.block_size = 16*1024;
	acfg.max_number_files = 100;

	nd = [[Nodes alloc] init];
	pg = [[Pages alloc] init];
	r = [[Region alloc] init];

	d = malloc(l*7);

	get_nodes_cdata(&nd, &pg, d);
	[r add: [nd xip]];
	[[nd xip] fsoffset: 0x4455667711223399UL];
	[r incore: 1];
	output = [r data];


//	u64 fsoffset;
	CuAssertHexEquals(tc, 0x44, output[0]);
	CuAssertHexEquals(tc, 0x55, output[1]);
	CuAssertHexEquals(tc, 0x66, output[2]);
	CuAssertHexEquals(tc, 0x77, output[3]);
	CuAssertHexEquals(tc, 0x11, output[4]);
	CuAssertHexEquals(tc, 0x22, output[5]);
	CuAssertHexEquals(tc, 0x33, output[6]);
	CuAssertHexEquals(tc, 0x99, output[7]);
//	u64 size;
	CuAssertHexEquals(tc, 0x00, output[8]);
	CuAssertHexEquals(tc, 0x00, output[9]);
	CuAssertHexEquals(tc, 0x00, output[10]);
	CuAssertHexEquals(tc, 0x00, output[11]);
	CuAssertHexEquals(tc, 0x00, output[12]);
	CuAssertHexEquals(tc, 0x00, output[13]);
	CuAssertHexEquals(tc, 0x00, output[14]);
	CuAssertHexEquals(tc, 0x00, output[15]);
//	u64 compressed_size;
	CuAssertHexEquals(tc, 0x00, output[16]);
	CuAssertHexEquals(tc, 0x00, output[17]);
	CuAssertHexEquals(tc, 0x00, output[18]);
	CuAssertHexEquals(tc, 0x00, output[19]);
	CuAssertHexEquals(tc, 0x00, output[20]);
	CuAssertHexEquals(tc, 0x00, output[21]);
	CuAssertHexEquals(tc, 0x00, output[22]);
	CuAssertHexEquals(tc, 0x00, output[23]);
//	u64 max_index;
	CuAssertHexEquals(tc, 0x00, output[24]);
	CuAssertHexEquals(tc, 0x00, output[25]);
	CuAssertHexEquals(tc, 0x00, output[26]);
	CuAssertHexEquals(tc, 0x00, output[27]);
	CuAssertHexEquals(tc, 0x00, output[28]);
	CuAssertHexEquals(tc, 0x00, output[29]);
	CuAssertHexEquals(tc, 0x00, output[30]);
	CuAssertHexEquals(tc, 0x00, output[31]);
//	u8 table_byte_depth;
	CuAssertHexEquals(tc, 0x00, output[32]);
//	u8 incore;
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
	SUITE_ADD_TEST(suite, Region_bytetable_data);
	SUITE_ADD_TEST(suite, Region_nodes_data);
	SUITE_ADD_TEST(suite, Region_bytetable_data_notcore);
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

#include "header.h"
#include "stubs.h"
#include "CuTest.h"

/* Including function under test */
#include "bytetable.h"
#include "bytetable.m"
#include "compressor.h"
#include "compressor.m"

/****** Test Code ******/

static void Bytetable_test_check_depth(CuTest *tc)
{
	uint8_t depth = 0;

	printf("Running %s\n", __FUNCTION__);

	depth = ByteTable_check_depth(depth,0x0);
	CuAssertIntEquals(tc, 1, depth);
	depth = ByteTable_check_depth(depth,0x01);
	CuAssertIntEquals(tc, 1, depth);
	depth = ByteTable_check_depth(depth,0x10);
	CuAssertIntEquals(tc, 1, depth);
	depth = ByteTable_check_depth(depth,0xFF);
	CuAssertIntEquals(tc, 1, depth);

	depth = ByteTable_check_depth(depth,0x0100);
	CuAssertIntEquals(tc, 2, depth);
	depth = ByteTable_check_depth(depth,0x1000);
	CuAssertIntEquals(tc, 2, depth);
	depth = ByteTable_check_depth(depth,0xFFff);
	CuAssertIntEquals(tc, 2, depth);
	depth = ByteTable_check_depth(depth,0x0);
	CuAssertIntEquals(tc, 2, depth);

	depth = ByteTable_check_depth(depth,0x010000);
	CuAssertIntEquals(tc, 3, depth);
	depth = ByteTable_check_depth(depth,0x100000);
	CuAssertIntEquals(tc, 3, depth);
	depth = ByteTable_check_depth(depth,0xFFffFF);
	CuAssertIntEquals(tc, 3, depth);
	depth = ByteTable_check_depth(depth,0x0);
	CuAssertIntEquals(tc, 3, depth);

	depth = ByteTable_check_depth(depth,0x01000000);
	CuAssertIntEquals(tc, 4, depth);
	depth = ByteTable_check_depth(depth,0x10000000);
	CuAssertIntEquals(tc, 4, depth);
	depth = ByteTable_check_depth(depth,0xFFffFFff);
	CuAssertIntEquals(tc, 4, depth);
	depth = ByteTable_check_depth(depth,0x0);
	CuAssertIntEquals(tc, 4, depth);

	depth = ByteTable_check_depth(depth,0x0100000000ULL);
	CuAssertIntEquals(tc, 5, depth);
	depth = ByteTable_check_depth(depth,0x1000000000ULL);
	CuAssertIntEquals(tc, 5, depth);
	depth = ByteTable_check_depth(depth,0xFFffFFffFFULL);
	CuAssertIntEquals(tc, 5, depth);
	depth = ByteTable_check_depth(depth,0x0);
	CuAssertIntEquals(tc, 5, depth);

	depth = ByteTable_check_depth(depth,0x010000000000ULL);
	CuAssertIntEquals(tc, 6, depth);
	depth = ByteTable_check_depth(depth,0x100000000000ULL);
	CuAssertIntEquals(tc, 6, depth);
	depth = ByteTable_check_depth(depth,0xFFffFFffFFffULL);
	CuAssertIntEquals(tc, 6, depth);
	depth = ByteTable_check_depth(depth,0x0);
	CuAssertIntEquals(tc, 6, depth);

	depth = ByteTable_check_depth(depth,0x01000000000000ULL);
	CuAssertIntEquals(tc, 7, depth);
	depth = ByteTable_check_depth(depth,0x10000000000000ULL);
	CuAssertIntEquals(tc, 7, depth);
	depth = ByteTable_check_depth(depth,0xFFffFFffFFffFFULL);
	CuAssertIntEquals(tc, 7, depth);
	depth = ByteTable_check_depth(depth,0x0);
	CuAssertIntEquals(tc, 7, depth);

	depth = ByteTable_check_depth(depth,0x0100000000000000ULL);
	CuAssertIntEquals(tc, 8, depth);
	depth = ByteTable_check_depth(depth,0x1000000000000000ULL);
	CuAssertIntEquals(tc, 8, depth);
	depth = ByteTable_check_depth(depth,0xFFffFFffFFffFFffULL);
	CuAssertIntEquals(tc, 8, depth);
	depth = ByteTable_check_depth(depth,0x0);
	CuAssertIntEquals(tc, 8, depth);
}

static void Bytetable_createdestroy(CuTest *tc)
{
	int output;

	ByteTable *bt = [[ByteTable alloc] init];

	printf("Running %s\n", __FUNCTION__);

	[bt numberEntries: 4096 dedup: false];
	[bt free];
	[bt release];

	bt = [[ByteTable alloc] init];
	[bt numberEntries: 4096 dedup: true];
	[bt free];
	[bt release];

	output = 0;
	CuAssertIntEquals(tc, 0, output);
}

static void Bytetable_add_1byte(CuTest *tc)
{
	ByteTable *bt = [[ByteTable alloc] init];
	uint64_t expected, actual;
	void *data;

	printf("Running %s\n", __FUNCTION__);

	[bt numberEntries: 4096 dedup: true];

	data = [bt add: 0x01];
	CuAssert(tc, "data should not be zero",data != 0);
	expected = (uint64_t)(data + sizeof(struct bytetable_value));
	actual = (uint64_t)[bt add: 0x00];
	CuAssertHexEquals(tc, expected, actual);
	expected = (uint64_t)(data + sizeof(struct bytetable_value)*2);
	actual = (uint64_t)[bt add: 0xFF];
	CuAssertHexEquals(tc, expected, actual);
	CuAssertIntEquals(tc, 3, [bt length]);
	CuAssertIntEquals(tc, 3, [bt size]);

	[bt free];
	[bt release];
}

static void Bytetable_add_a_size(CuTest *tc, uint64_t *inputs, uint64_t *outputs, bool dedup)
{
	ByteTable *bt = [[ByteTable alloc] init];

	[bt numberEntries: 4096 dedup: dedup];

	outputs[0] = (uint64_t)[bt add: inputs[0] ];
	outputs[1] = (uint64_t)[bt add: inputs[1] ];
	outputs[2] = (uint64_t)[bt add: inputs[2] ];
	outputs[3] = [bt length];
	outputs[4] = [bt size];

	[bt free];
	[bt release];
}

static void Bytetable_add_allsize(CuTest *tc)
{
	uint64_t inputs[3];
	uint64_t outputs[5];
	uint64_t expected;
	uint64_t size;

	printf("Running %s\n", __FUNCTION__);
	inputs[1] = 0x00;

	inputs[0] = 0x01;
	inputs[2] = 0xFF;
	size = 3;
	Bytetable_add_a_size(tc, inputs, outputs, true);
	CuAssert(tc, "outputs[0] should not be zero",outputs[0] != 0);
	expected = outputs[0] + sizeof(struct bytetable_value);
	CuAssertHexEquals(tc, expected, outputs[1] );
	expected = outputs[0] + sizeof(struct bytetable_value)*2;
	CuAssertHexEquals(tc, expected, outputs[2] );
	CuAssertIntEquals(tc, 3, outputs[3] );
	CuAssertIntEquals(tc, size, outputs[4] );

	inputs[0] = 0x0100;
	inputs[2] = 0xFFFF;
	size = 6;
	Bytetable_add_a_size(tc, inputs, outputs, true);
	CuAssert(tc, "outputs[0] should not be zero",outputs[0] != 0);
	expected = outputs[0] + sizeof(struct bytetable_value);
	CuAssertHexEquals(tc, expected, outputs[1] );
	expected = outputs[0] + sizeof(struct bytetable_value)*2;
	CuAssertHexEquals(tc, expected, outputs[2] );
	CuAssertIntEquals(tc, 3, outputs[3] );
	CuAssertIntEquals(tc, size, outputs[4] );

	inputs[0] = 0x010000;
	inputs[2] = 0xFFFFFF;
	size = 9;
	Bytetable_add_a_size(tc, inputs, outputs, true);
	CuAssert(tc, "outputs[0] should not be zero",outputs[0] != 0);
	expected = outputs[0] + sizeof(struct bytetable_value);
	CuAssertHexEquals(tc, expected, outputs[1] );
	expected = outputs[0] + sizeof(struct bytetable_value)*2;
	CuAssertHexEquals(tc, expected, outputs[2] );
	CuAssertIntEquals(tc, 3, outputs[3] );
	CuAssertIntEquals(tc, size, outputs[4] );

	inputs[0] = 0x01000000;
	inputs[2] = 0xFFFFFFFF;
	size = 12;
	Bytetable_add_a_size(tc, inputs, outputs, true);
	CuAssert(tc, "outputs[0] should not be zero",outputs[0] != 0);
	expected = outputs[0] + sizeof(struct bytetable_value);
	CuAssertHexEquals(tc, expected, outputs[1] );
	expected = outputs[0] + sizeof(struct bytetable_value)*2;
	CuAssertHexEquals(tc, expected, outputs[2] );
	CuAssertIntEquals(tc, 3, outputs[3] );
	CuAssertIntEquals(tc, size, outputs[4] );

	inputs[0] = 0x0100000000;
	inputs[2] = 0xFFFFFFFFFF;
	size = 15;
	Bytetable_add_a_size(tc, inputs, outputs, true);
	CuAssert(tc, "outputs[0] should not be zero",outputs[0] != 0);
	expected = outputs[0] + sizeof(struct bytetable_value);
	CuAssertHexEquals(tc, expected, outputs[1] );
	expected = outputs[0] + sizeof(struct bytetable_value)*2;
	CuAssertHexEquals(tc, expected, outputs[2] );
	CuAssertIntEquals(tc, 3, outputs[3] );
	CuAssertIntEquals(tc, size, outputs[4] );

	inputs[0] = 0x010000000000;
	inputs[2] = 0xFFFFFFFFFFFF;
	size = 18;
	Bytetable_add_a_size(tc, inputs, outputs, true);
	CuAssert(tc, "outputs[0] should not be zero",outputs[0] != 0);
	expected = outputs[0] + sizeof(struct bytetable_value);
	CuAssertHexEquals(tc, expected, outputs[1] );
	expected = outputs[0] + sizeof(struct bytetable_value)*2;
	CuAssertHexEquals(tc, expected, outputs[2] );
	CuAssertIntEquals(tc, 3, outputs[3] );
	CuAssertIntEquals(tc, size, outputs[4] );

	inputs[0] = 0x01000000000000;
	inputs[2] = 0xFFFFFFFFFFFFFF;
	size = 21;
	Bytetable_add_a_size(tc, inputs, outputs, true);
	CuAssert(tc, "outputs[0] should not be zero",outputs[0] != 0);
	expected = outputs[0] + sizeof(struct bytetable_value);
	CuAssertHexEquals(tc, expected, outputs[1] );
	expected = outputs[0] + sizeof(struct bytetable_value)*2;
	CuAssertHexEquals(tc, expected, outputs[2] );
	CuAssertIntEquals(tc, 3, outputs[3] );
	CuAssertIntEquals(tc, size, outputs[4] );

	inputs[0] = 0x0100000000000000;
	inputs[2] = 0xFFFFFFFFFFFFFFFF;
	size = 24;
	Bytetable_add_a_size(tc, inputs, outputs, true);
	CuAssert(tc, "outputs[0] should not be zero",outputs[0] != 0);
	expected = outputs[0] + sizeof(struct bytetable_value);
	CuAssertHexEquals(tc, expected, outputs[1] );
	expected = outputs[0] + sizeof(struct bytetable_value)*2;
	CuAssertHexEquals(tc, expected, outputs[2] );
	CuAssertIntEquals(tc, 3, outputs[3] );
	CuAssertIntEquals(tc, size, outputs[4] );
}

static void Bytetable_depdup(CuTest *tc)
{
	uint64_t inputs[3];
	uint64_t outputs[5];
	uint64_t expected;
	uint64_t size, length;

	printf("Running %s\n", __FUNCTION__);
	inputs[0] = 0x00;
	inputs[1] = 0x01;
	inputs[2] = 0xFF;
	size = 3;
	length = 3;
	Bytetable_add_a_size(tc, inputs, outputs, true);
	//first pointer
	CuAssert(tc, "outputs[0] should not be zero",outputs[0] != 0);
	//second pointer
	expected = outputs[0] + sizeof(struct bytetable_value);
	CuAssertHexEquals(tc, expected, outputs[1] );
	//third pointer
	expected = outputs[0] + sizeof(struct bytetable_value)*2;
	CuAssertHexEquals(tc, expected, outputs[2] );
	CuAssertIntEquals(tc, length, outputs[3] );
	CuAssertIntEquals(tc, size, outputs[4] );

	inputs[0] = 0x00;
	inputs[1] = 0x01;
	inputs[2] = 0x01;
	size = 2;
	length = 2;
	Bytetable_add_a_size(tc, inputs, outputs, true);
	CuAssert(tc, "outputs[0] should not be zero",outputs[0] != 0);
	expected = outputs[0] + sizeof(struct bytetable_value);
	CuAssertHexEquals(tc, expected, outputs[1] );
	expected = outputs[1];
	CuAssertHexEquals(tc, expected, outputs[2] );
	CuAssertIntEquals(tc, length, outputs[3] );
	CuAssertIntEquals(tc, size, outputs[4] );

	inputs[0] = 0x01;
	inputs[1] = 0x01;
	inputs[2] = 0x01;
	size = 1;
	length = 1;
	Bytetable_add_a_size(tc, inputs, outputs, true);
	CuAssert(tc, "outputs[0] should not be zero",outputs[0] != 0);
	expected = outputs[0];
	CuAssertHexEquals(tc, expected, outputs[1] );
	expected = outputs[0];
	CuAssertHexEquals(tc, expected, outputs[2] );
	CuAssertIntEquals(tc, length, outputs[3] );
	CuAssertIntEquals(tc, size, outputs[4] );


	inputs[0] = 0x00;
	inputs[1] = 0x01;
	inputs[2] = 0xFF;
	size = 3;
	length = 3;
	Bytetable_add_a_size(tc, inputs, outputs, false);
	CuAssert(tc, "outputs[0] should not be zero",outputs[0] != 0);
	expected = outputs[0] + sizeof(struct bytetable_value);
	CuAssertHexEquals(tc, expected, outputs[1] );
	expected = outputs[0] + sizeof(struct bytetable_value)*2;
	CuAssertHexEquals(tc, expected, outputs[2] );
	CuAssertIntEquals(tc, length, outputs[3] );
	CuAssertIntEquals(tc, size, outputs[4] );

	inputs[0] = 0x00;
	inputs[1] = 0x01;
	inputs[2] = 0x01;
	size = 3;
	length = 3;
	Bytetable_add_a_size(tc, inputs, outputs, false);
	CuAssert(tc, "outputs[0] should not be zero",outputs[0] != 0);
	expected = outputs[0] + sizeof(struct bytetable_value);
	CuAssertHexEquals(tc, expected, outputs[1] );
	expected = outputs[0] + sizeof(struct bytetable_value)*2;
	CuAssertHexEquals(tc, expected, outputs[2] );
	CuAssertIntEquals(tc, length, outputs[3] );
	CuAssertIntEquals(tc, size, outputs[4] );

	inputs[0] = 0x01;
	inputs[1] = 0x01;
	inputs[2] = 0x01;
	size = 3;
	length = 3;
	Bytetable_add_a_size(tc, inputs, outputs, false);
	CuAssert(tc, "outputs[0] should not be zero",outputs[0] != 0);
	expected = outputs[0] + sizeof(struct bytetable_value);
	CuAssertHexEquals(tc, expected, outputs[1] );
	expected = outputs[0] + sizeof(struct bytetable_value)*2;
	CuAssertHexEquals(tc, expected, outputs[2] );
	CuAssertIntEquals(tc, length, outputs[3] );
	CuAssertIntEquals(tc, size, outputs[4] );
}

static void Bytetable_simpledata(CuTest *tc)
{
	uint8_t *output;
	uint64_t size;

	ByteTable *bt = [[ByteTable alloc] init];

	printf("Running %s\n", __FUNCTION__);

	[bt numberEntries: 4096 dedup: true];
	
	[bt add: 0x123456];
	[bt add: 0x0];
	[bt add: 0x789ABC];

	output = [bt data];
	size = [bt size];
	CuAssertIntEquals(tc, 9, size);
	CuAssertHexEquals(tc, 0x12, output[0]);
	CuAssertHexEquals(tc, 0x34, output[1]);
	CuAssertHexEquals(tc, 0x56, output[2]);
	CuAssertHexEquals(tc, 0x00, output[3]);
	CuAssertHexEquals(tc, 0x00, output[4]);
	CuAssertHexEquals(tc, 0x00, output[5]);
	CuAssertHexEquals(tc, 0x78, output[6]);
	CuAssertHexEquals(tc, 0x9A, output[7]);
	CuAssertHexEquals(tc, 0xBC, output[8]);
	[bt free];
	[bt release];
}

static void Bytetable_cdata(CuTest *tc)
{
	ByteTable *bt = [[ByteTable alloc] init];
	int i;

	printf("Running %s\n", __FUNCTION__);

	[bt numberEntries: 4096 dedup: true];
	
	[bt add: 0x123456];
	[bt add: 0x0];
	for (i=0;i<1000;i++) {
		[bt add: 0x789000 + i];
	}
	[bt data];

	//printf("csize = %i  size = %i\n",(int)[bt csize],(int)[bt size]);
	CuAssertTrue(tc,[bt csize] <= [bt size]);
	CuAssertTrue(tc,[bt csize] > 0);

	[bt free];
	[bt release];
}

/****** End Test Code ******/


static CuSuite* GetSuite(void){
	CuSuite* suite = CuSuiteNew();

	SUITE_ADD_TEST(suite, Bytetable_test_check_depth);
	SUITE_ADD_TEST(suite, Bytetable_createdestroy);
	SUITE_ADD_TEST(suite, Bytetable_add_1byte);
	SUITE_ADD_TEST(suite, Bytetable_add_allsize);
	SUITE_ADD_TEST(suite, Bytetable_depdup);
	SUITE_ADD_TEST(suite, Bytetable_simpledata);
	SUITE_ADD_TEST(suite, Bytetable_cdata);
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


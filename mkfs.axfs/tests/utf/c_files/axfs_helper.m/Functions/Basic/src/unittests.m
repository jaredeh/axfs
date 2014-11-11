#include "header.h"
#include "stubs.h"
#include "CuTest.h"

/* Including function under test */
#include "axfs_helper.m"

/****** Test Code ******/

struct axfs_config acfg;

static void AxfsHelper_align(CuTest *tc){
	NSString *ah = @"dd";
	uint64_t align;
	uint64_t output;

	printf("Running %s\n", __FUNCTION__);

	align = 4096;
	output = [ah alignNumber: 0 bytes: align];
	CuAssertHexEquals(tc, 0, output);
	output = [ah alignNumber: 1 bytes: align];
	CuAssertHexEquals(tc, align, output);
	output = [ah alignNumber: 4095 bytes: align];
	CuAssertHexEquals(tc, align, output);
	output = [ah alignNumber: 4096 bytes: align];
	CuAssertHexEquals(tc, align, output);
	output = [ah alignNumber: 4097 bytes: align];
	CuAssertHexEquals(tc, align*2, output);
	output = [ah alignNumber: 8191 bytes: align];
	CuAssertHexEquals(tc, align*2, output);
	output = [ah alignNumber: 8192 bytes: align];
	CuAssertHexEquals(tc, align*2, output);
	output = [ah alignNumber: 8193 bytes: align];
	CuAssertHexEquals(tc, align*3, output);

	align = 1;
	output = [ah alignNumber: 0 bytes: align];
	CuAssertHexEquals(tc, 0, output);
	output = [ah alignNumber: 1 bytes: align];
	CuAssertHexEquals(tc, 1, output);
	output = [ah alignNumber: 2 bytes: align];
	CuAssertHexEquals(tc, 2, output);
	output = [ah alignNumber: 3 bytes: align];
	CuAssertHexEquals(tc, 3, output);
	output = [ah alignNumber: 4 bytes: align];
	CuAssertHexEquals(tc, 4, output);

	align = 2;
	output = [ah alignNumber: 0 bytes: align];
	CuAssertHexEquals(tc, 0, output);
	output = [ah alignNumber: 1 bytes: align];
	CuAssertHexEquals(tc, 2, output);
	output = [ah alignNumber: 2 bytes: align];
	CuAssertHexEquals(tc, 2, output);
	output = [ah alignNumber: 3 bytes: align];
	CuAssertHexEquals(tc, 4, output);
	output = [ah alignNumber: 4 bytes: align];
	CuAssertHexEquals(tc, 4, output);

	align = 3;
	output = [ah alignNumber: 0 bytes: align];
	CuAssertHexEquals(tc, 0, output);
	output = [ah alignNumber: 1 bytes: align];
	CuAssertHexEquals(tc, 3, output);
	output = [ah alignNumber: 2 bytes: align];
	CuAssertHexEquals(tc, 3, output);
	output = [ah alignNumber: 3 bytes: align];
	CuAssertHexEquals(tc, 3, output);
	output = [ah alignNumber: 4 bytes: align];
	CuAssertHexEquals(tc, 6, output);
}

static void AxfsHelper_outputByte(CuTest *tc){
	NSString *ah = @"dd";
	uint8_t output;

	printf("Running %s\n", __FUNCTION__);
	//-(uint8_t) outputByte: (uint64_t) datum byte: (uint8_t) i;
	output = [ah outputByte: 0x1817161514131211 byte: 7];
	CuAssertHexEquals(tc, 0x18, output);
	output = [ah outputByte: 0x1817161514131211 byte: 6];
	CuAssertHexEquals(tc, 0x17, output);
	output = [ah outputByte: 0x1817161514131211 byte: 5];
	CuAssertHexEquals(tc, 0x16, output);
	output = [ah outputByte: 0x1817161514131211 byte: 4];
	CuAssertHexEquals(tc, 0x15, output);
	output = [ah outputByte: 0x1817161514131211 byte: 3];
	CuAssertHexEquals(tc, 0x14, output);
	output = [ah outputByte: 0x1817161514131211 byte: 2];
	CuAssertHexEquals(tc, 0x13, output);
	output = [ah outputByte: 0x1817161514131211 byte: 1];
	CuAssertHexEquals(tc, 0x12, output);
	output = [ah outputByte: 0x1817161514131211 byte: 0];
	CuAssertHexEquals(tc, 0x11, output);
}

static void AxfsHelper_outputDatum(CuTest *tc){
	NSString *ah = @"dd";
	uint8_t *output;
	uint8_t *buffer;

	printf("Running %s\n", __FUNCTION__);
	//-(uint8_t *) outputDatum: (uint64_t) datum depth: (uint8_t) depth buffer: (uint8_t *) buffer;

	buffer = malloc(16000);
	output = [ah outputDatum: 0x1817161514131211 depth: 8 buffer: buffer];
	CuAssertHexEquals(tc, 0x18, *buffer);
	output = [ah outputDatum: 0x1817161514131211 depth: 7 buffer: buffer];
	CuAssertHexEquals(tc, 0x17, *buffer);
	output = [ah outputDatum: 0x1817161514131211 depth: 6 buffer: buffer];
	CuAssertHexEquals(tc, 0x16, *buffer);
	output = [ah outputDatum: 0x1817161514131211 depth: 5 buffer: buffer];
	CuAssertHexEquals(tc, 0x15, *buffer);
	output = [ah outputDatum: 0x1817161514131211 depth: 4 buffer: buffer];
	CuAssertHexEquals(tc, 0x14, *buffer);
	output = [ah outputDatum: 0x1817161514131211 depth: 3 buffer: buffer];
	CuAssertHexEquals(tc, 0x13, *buffer);
	output = [ah outputDatum: 0x1817161514131211 depth: 2 buffer: buffer];
	CuAssertHexEquals(tc, 0x12, *buffer);
	output = [ah outputDatum: 0x1817161514131211 depth: 1 buffer: buffer];
	CuAssertHexEquals(tc, 0x11, *buffer);

}

static void AxfsHelper_bigEndianize(CuTest *tc){
	NSString *ah = @"dd";
	uint8_t *output;

	printf("Running %s\n", __FUNCTION__);
	//-(void) bigEndianize: (uint64_t) number ptr: (uint8_t *) ptr bytes: (int) j;

	output = malloc(16000);
	[ah bigEndianize: 0x1817161514131211 ptr: output bytes: 1];
	CuAssertHexEquals(tc, 0x11, output[0]);
	[ah bigEndianize: 0x1817161514131211 ptr: output bytes: 2];
	CuAssertHexEquals(tc, 0x12, output[0]);
	CuAssertHexEquals(tc, 0x11, output[1]);
	CuAssertHexEquals(tc, 0x0, output[2]);
	[ah bigEndianize: 0x1817161514131211 ptr: output bytes: 3];
	CuAssertHexEquals(tc, 0x13, output[0]);
	CuAssertHexEquals(tc, 0x12, output[1]);
	CuAssertHexEquals(tc, 0x11, output[2]);
	CuAssertHexEquals(tc, 0x0, output[3]);
	[ah bigEndianize: 0x1817161514131211 ptr: output bytes: 4];
	CuAssertHexEquals(tc, 0x14, output[0]);
	CuAssertHexEquals(tc, 0x13, output[1]);
	CuAssertHexEquals(tc, 0x12, output[2]);
	CuAssertHexEquals(tc, 0x11, output[3]);
	CuAssertHexEquals(tc, 0x0, output[4]);
	[ah bigEndianize: 0x1817161514131211 ptr: output bytes: 8];
	CuAssertHexEquals(tc, 0x18, output[0]);
	CuAssertHexEquals(tc, 0x17, output[1]);
	CuAssertHexEquals(tc, 0x16, output[2]);
	CuAssertHexEquals(tc, 0x15, output[3]);
	CuAssertHexEquals(tc, 0x14, output[4]);
	CuAssertHexEquals(tc, 0x13, output[5]);
	CuAssertHexEquals(tc, 0x12, output[6]);
	CuAssertHexEquals(tc, 0x11, output[7]);
	CuAssertHexEquals(tc, 0x0, output[8]);
}

static void AxfsHelper_bigEndian64(CuTest *tc){
	NSString *ah = @"dd";
	uint8_t *output;

	printf("Running %s\n", __FUNCTION__);
	//-(void) bigEndian64: (uint64_t) number ptr: (uint8_t *) ptr;

	output = malloc(16000);
	[ah bigEndian64: 0x1817161514131211 ptr: output];
	CuAssertHexEquals(tc, 0x18, output[0]);
	CuAssertHexEquals(tc, 0x17, output[1]);
	CuAssertHexEquals(tc, 0x16, output[2]);
	CuAssertHexEquals(tc, 0x15, output[3]);
	CuAssertHexEquals(tc, 0x14, output[4]);
	CuAssertHexEquals(tc, 0x13, output[5]);
	CuAssertHexEquals(tc, 0x12, output[6]);
	CuAssertHexEquals(tc, 0x11, output[7]);
	CuAssertHexEquals(tc, 0x0, output[8]);
}

static void AxfsHelper_bigEndian32(CuTest *tc){
	NSString *ah = @"dd";
	uint8_t *output;

	printf("Running %s\n", __FUNCTION__);
	//-(void) bigEndian32: (uint32_t) number ptr: (uint8_t *) ptr;

	output = malloc(16000);
	[ah bigEndian32: 0x14131211 ptr: output];
	CuAssertHexEquals(tc, 0x14, output[0]);
	CuAssertHexEquals(tc, 0x13, output[1]);
	CuAssertHexEquals(tc, 0x12, output[2]);
	CuAssertHexEquals(tc, 0x11, output[3]);
	CuAssertHexEquals(tc, 0x0, output[4]);
}

static void AxfsHelper_bigEndian16(CuTest *tc){
	NSString *ah = @"dd";
	uint8_t *output;
	uint8_t *buffer;

	printf("Running %s\n", __FUNCTION__);
	//-(void) bigEndian16: (uint16_t) number ptr: (uint8_t *) ptr;

	buffer = malloc(16000);
	output = buffer;
	output = [ah bigEndian16: 0x1211 ptr: output];
	CuAssertHexEquals(tc, 0x12, buffer[0]);
	CuAssertHexEquals(tc, 0x11, buffer[1]);
	CuAssertHexEquals(tc, 0x0, buffer[2]);
	output = [ah bigEndian16: 0x1a1b ptr: output];
	CuAssertHexEquals(tc, 0x12, buffer[0]);
	CuAssertHexEquals(tc, 0x11, buffer[1]);
	CuAssertHexEquals(tc, 0x1a, buffer[2]);
	CuAssertHexEquals(tc, 0x1b, buffer[3]);
	CuAssertHexEquals(tc, 0x00, buffer[4]);
}


static void AxfsHelper_bigEndianByte(CuTest *tc){
	NSString *ah = @"dd";
	uint8_t *output;
	uint8_t *buffer;

	printf("Running %s\n", __FUNCTION__);
	//-(void) bigEndianByte: (uint8_t) number ptr: (uint8_t *) ptr;

	buffer = malloc(16000);
	output = buffer;
	output = [ah bigEndianByte: 0x11 ptr: output];
	CuAssertHexEquals(tc, 0x11, buffer[0]);
	CuAssertHexEquals(tc, 0x0, buffer[1]);
	output = [ah bigEndianByte: 0x1a ptr: output];
	CuAssertHexEquals(tc, 0x1a, buffer[1]);
	CuAssertHexEquals(tc, 0x0, buffer[2]);
	output = [ah bigEndianByte: 0x1b ptr: output];
	CuAssertHexEquals(tc, 0x11, buffer[0]);
	CuAssertHexEquals(tc, 0x1a, buffer[1]);
	CuAssertHexEquals(tc, 0x1b, buffer[2]);
	CuAssertHexEquals(tc, 0x00, buffer[3]);
}


/****** End Test Code ******/


static CuSuite* GetSuite(void){
	CuSuite* suite = CuSuiteNew();

	SUITE_ADD_TEST(suite, AxfsHelper_align);
	SUITE_ADD_TEST(suite, AxfsHelper_outputByte);
	SUITE_ADD_TEST(suite, AxfsHelper_outputDatum);
	SUITE_ADD_TEST(suite, AxfsHelper_bigEndianize);
	SUITE_ADD_TEST(suite, AxfsHelper_bigEndian64);
	SUITE_ADD_TEST(suite, AxfsHelper_bigEndian32);
	SUITE_ADD_TEST(suite, AxfsHelper_bigEndian16);
	SUITE_ADD_TEST(suite, AxfsHelper_bigEndianByte);
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


#include "header.h"
#include "stubs.h"
#include "CuTest.h"

/* Including function under test */
#include "modes.m"
#include "btree_object.m"

/****** Test Code ******/

struct axfs_config acfg;

NSDictionary *makeattribs(uint32_t igid, uint32_t iuid, uint16_t imode)
{
	NSNumber *ngid = [NSNumber numberWithUnsignedLong: (unsigned long) igid];
	NSNumber *nuid = [NSNumber numberWithUnsignedLong: (unsigned long) iuid];
	NSNumber *nmode = [NSNumber numberWithShort: (short) imode];
	NSDictionary *attribs;

	attribs = [NSDictionary dictionaryWithObjectsAndKeys: ngid, NSFileGroupOwnerAccountID, nuid, NSFileOwnerAccountID, nmode, NSFilePosixPermissions, nil];
	return attribs;
}

static void Modes_createdestroy(CuTest *tc)
{
	Modes *modes;
	int output;
	printf("Running %s\n", __FUNCTION__);
	acfg.max_nodes = 100;
	acfg.block_size = 16*1024;
	acfg.page_size = 4096;
	acfg.compression = "lzo";
	acfg.max_number_files = 100;

	modes = [[Modes alloc] init];
	[modes free];
	[modes release];

	output = 0;
	CuAssertIntEquals(tc, 0, output);
}

static void Modes_one_node(CuTest *tc)
{
	Modes *modes;
	int length;
	struct mode_struct *mode;
	NSDictionary *attr;
	printf("Running %s\n", __FUNCTION__);
	acfg.max_nodes = 100;
	acfg.block_size = 16*1024;
	acfg.page_size = 4096;
	acfg.compression = "lzo";
	acfg.max_number_files = 100;

	modes = [[Modes alloc] init];
	length = [modes length];
	CuAssertIntEquals(tc, 0, length);
	attr = makeattribs(2, 5, 44);
	mode = [modes addMode: attr];
	length = [modes length];
	CuAssertIntEquals(tc, 1, length);
	CuAssertIntEquals(tc, 2, mode->gid);
	CuAssertIntEquals(tc, 5, mode->uid);
	CuAssertIntEquals(tc, 44, mode->mode);


	[modes free];
	[modes release];
}

static void Modes_two_node(CuTest *tc)
{
	Modes *modes;
	int length;
	struct mode_struct *mode;
	NSDictionary *attr;
	printf("Running %s\n", __FUNCTION__);
	acfg.max_nodes = 100;
	acfg.block_size = 16*1024;
	acfg.page_size = 4096;
	acfg.compression = "lzo";
	acfg.max_number_files = 100;

	modes = [[Modes alloc] init];
	length = [modes length];
	CuAssertIntEquals(tc, 0, length);
	attr = makeattribs(2, 5, 44);
	mode = [modes addMode: attr];
	length = [modes length];
	CuAssertIntEquals(tc, 1, length);
	CuAssertIntEquals(tc, 2, mode->gid);
	CuAssertIntEquals(tc, 5, mode->uid);
	CuAssertIntEquals(tc, 44, mode->mode);
	attr = makeattribs(11, 33, 55);
	mode = [modes addMode: attr];
	length = [modes length];
	CuAssertIntEquals(tc, 2, length);
	CuAssertIntEquals(tc, 11, mode->gid);
	CuAssertIntEquals(tc, 33, mode->uid);
	CuAssertIntEquals(tc, 55, mode->mode);

	[modes free];
	[modes release];
}

static void Modes_dup_nodes(CuTest *tc)
{
	Modes *modes;
	int length;
	struct mode_struct *mode;
	struct mode_struct *modea;
	struct mode_struct *modeb;
	NSDictionary *attr;
	printf("Running %s\n", __FUNCTION__);
	acfg.max_nodes = 100;
	acfg.block_size = 16*1024;
	acfg.page_size = 4096;
	acfg.compression = "lzo";
	acfg.max_number_files = 100;
	
	modes = [[Modes alloc] init];
	length = [modes length];
	CuAssertIntEquals(tc, 0, length);
	attr = makeattribs(2, 5, 44);
	mode = [modes addMode: attr];
	length = [modes length];
	CuAssertIntEquals(tc, 1, length);
	CuAssertIntEquals(tc, 2, mode->gid);
	CuAssertIntEquals(tc, 5, mode->uid);
	CuAssertIntEquals(tc, 44, mode->mode);
	attr = makeattribs(11, 33, 55);
	modea = [modes addMode: attr];
	length = [modes length];
	CuAssertIntEquals(tc, 2, length);
	CuAssertIntEquals(tc, 11, modea->gid);
	CuAssertIntEquals(tc, 33, modea->uid);
	CuAssertIntEquals(tc, 55, modea->mode);
	attr = makeattribs(11, 33, 55);
	modeb = [modes addMode: attr];
	length = [modes length];
	CuAssertIntEquals(tc, 2, length);
	CuAssertIntEquals(tc, 11, modeb->gid);
	CuAssertIntEquals(tc, 33, modeb->uid);
	CuAssertIntEquals(tc, 55, modeb->mode);
	CuAssertPtrEquals(tc,modea,modeb);
	attr = makeattribs(2, 5, 44);
	mode = [modes addMode: attr];
	length = [modes length];
	CuAssertIntEquals(tc, 2, length);
	CuAssertIntEquals(tc, 2, mode->gid);
	CuAssertIntEquals(tc, 5, mode->uid);
	CuAssertIntEquals(tc, 44, mode->mode);
	attr = makeattribs(2, 5, 41);
	mode = [modes addMode: attr];
	length = [modes length];
	CuAssertIntEquals(tc, 3, length);
	CuAssertIntEquals(tc, 2, mode->gid);
	CuAssertIntEquals(tc, 5, mode->uid);
	CuAssertIntEquals(tc, 41, mode->mode);

	[modes free];
	[modes release];
}
/*
void print_data(void *d, uint64_t l)
{
	int i;
	uint8_t *c = d;

	for(i=0;i<l;i++) {
		printf("%02x",c[i]);
	}
	printf("\n");
}
*/

/****** End Test Code ******/

static CuSuite* GetSuite(void){
	CuSuite* suite = CuSuiteNew();

	SUITE_ADD_TEST(suite, Modes_createdestroy);
	SUITE_ADD_TEST(suite, Modes_one_node);
	SUITE_ADD_TEST(suite, Modes_two_node);
	SUITE_ADD_TEST(suite, Modes_dup_nodes);
//	SUITE_ADD_TEST(suite, );
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


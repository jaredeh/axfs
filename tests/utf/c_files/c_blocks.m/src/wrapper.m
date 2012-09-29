#import <Foundation/Foundation.h>
#import "c_blocks.h"
#import "c_blocks.m"
#include "compressor.h"
#include "compressor.m"
#import <Foundation/NSAutoreleasePool.h>

struct axfs_config acfg;
NSAutoreleasePool *pool;

void CBlocks___addNode(CBlocks *cb, struct axfs_node * node)
{
	return [cb addNode: node];
}

void *CBlocks___data(CBlocks *cb)
{
	return [cb data];
}

uint64_t CBlocks___size(CBlocks *cb)
{
	return [cb size];
}

uint64_t CBlocks___length(CBlocks *cb)
{
	return [cb length];
}

CBlocks *CBlocks___new(void)
{
	return [[CBlocks alloc] init];
}

void CBlocks___initialize(CBlocks *cb)
{
	pool = [[NSAutoreleasePool alloc] init];
	[cb initialize];
}

void CBlocks___free(CBlocks *cb)
{
	[cb free];
	[cb release];
	[pool drain];
    CBlocks__free_acfg();
}

void CBlocks__free_acfg(void)
{
    free(acfg.input);
    free(acfg.output);
    free(acfg.secondary_output);
    free(acfg.compression);
    free(acfg.page_size_str);
    free(acfg.block_size_str);
    free(acfg.xip_size_str);
    free(acfg.profile);
    free(acfg.special);
}

void CBlocks___init_acfg(void)
{
    if( acfg.input != 0)
        return;
    acfg.input = malloc(1024);
    acfg.output = malloc(1024);
    acfg.secondary_output = malloc(1024);
    acfg.compression = malloc(1024);
    acfg.page_size_str = malloc(1024);
    acfg.block_size_str = malloc(1024);
    acfg.xip_size_str = malloc(1024);
    acfg.profile = malloc(1024);
    acfg.special = malloc(1024);
}

void CBlocks___set_acfg(struct axfs_config *cfg)
{
    CBlocks___init_acfg();
    memset(acfg.input,0,1024);
    memset(acfg.output,0,1024);
    memset(acfg.secondary_output,0,1024);
    memset(acfg.compression,0,1024);
    memset(acfg.page_size_str,0,1024);
    memset(acfg.block_size_str,0,1024);
    memset(acfg.xip_size_str,0,1024);
    memset(acfg.profile,0,1024);
    memset(acfg.special,0,1024);

    memcpy(acfg.input,cfg->input,strlen(cfg->input));
    memcpy(acfg.output,cfg->output,strlen(cfg->output));
    memcpy(acfg.secondary_output,cfg->secondary_output,strlen(cfg->secondary_output));
    memcpy(acfg.compression,cfg->compression,strlen(cfg->compression));
    memcpy(acfg.page_size_str,cfg->page_size_str,strlen(cfg->page_size_str));
    memcpy(acfg.block_size_str,cfg->block_size_str,strlen(cfg->block_size_str));
    memcpy(acfg.xip_size_str,cfg->xip_size_str,strlen(cfg->xip_size_str));
    memcpy(acfg.profile,cfg->profile,strlen(cfg->profile));
    memcpy(acfg.special,cfg->special,strlen(cfg->special));

    acfg.page_size = cfg->page_size;
    acfg.block_size = cfg->block_size;
    acfg.xip_size = cfg->xip_size;
    acfg.max_nodes = cfg->max_nodes;
}


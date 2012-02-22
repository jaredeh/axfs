void *get_data(ByteTable *bt, Nodes *nd) {
	if (nd == NULL)
		return [bt data];
	return [nd data];
}

void *get_cdata(ByteTable *bt, Nodes *nd) {
	if (nd == NULL)
		return [bt cdata];
	return [nd cdata];
}

uint64_t get_size(ByteTable *bt, Nodes *nd) {
	if (nd == NULL)
		return [bt size];
	return [nd size];
}

uint64_t get_csize(ByteTable *bt, Nodes *nd) {
	if (nd == NULL)
		return [bt csize];
	return [nd csize];
}

@implementation Region {
	uint64_t size;
	ByteTable *bytetable;
	Nodes *nodes;
	void *data;
}

-(void) addBytetable: (ByteTable *) bt {
	bytetable = bt;
	nodes = NULL;
}

-(void) addNodes: (Nodes *) nd {
	nodes = nd;
	bytetable = NULL;
}

-(void *) data {
	return 0;
}

-(void) free {
}

@end


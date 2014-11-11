import gzip, zlib
from lib.region import *

class ByteTable:

    def setup(self,mymap):
        print ":-"
        print self.regiondesc.size
        print "-"
        print self.regiondesc.compressed_size
        print "-;\n"
        if self.regiondesc.size > self.regiondesc.compressed_size and self.regiondesc.size > 1:
            self.data = zlib.decompress(self.region.data,-15)
        else:
            self.data = self.region.data

    def __init__(self,mymap,regiondesc):
        self.region = Region(mymap,regiondesc)
        self.regiondesc = regiondesc
        self.depth = self.regiondesc.table_byte_depth
        if self.depth < 1:
            NameError("table_byte_depth needs to be > 1, is '"+str(self.depth)+"'")
        self.max_index = self.regiondesc.max_index
        if self.max_index < 1:
            NameError("max_index needs to be > 1, is '"+str(self.max_index)+"'")
        self.setup(mymap)

    def __getitem__(self,num):
        cmd = "bytetable num='"+str(num)+"' greater than max_index="+str(self.max_index)
        if num > self.max_index:
            raise NameError(cmd)
        offset = num*self.depth
        d = self.data[offset:offset+self.depth]
        da = struct.unpack("!"+"B"*self.depth,d)
        value = 0
        for i in range(0,self.depth):
            j = i*256
            if j == 0:
                j = 1
            value += j*da[self.depth-1-i]
        return value

    def printdata(self):
        self.region.printme()

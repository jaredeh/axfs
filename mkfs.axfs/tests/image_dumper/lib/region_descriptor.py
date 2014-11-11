import mmap
import struct
from collections import namedtuple

from lib.helpers import *

regiondesc_attrs = 'fsoffset size compressed_size max_index'
regiondesc_attrs += ' table_byte_depth incore'

RDTuple = namedtuple('RegionDescriptor', regiondesc_attrs)

class RegionDescriptor:

    def setup(self,mymap,offset):
        if offset+34 > mymap.size():
            return "Trying to access past the end of the map: mymap.size='" + \
                   str(mymap.size()) + "' offset+34='" + str(offset+34) + "'"
        if offset < 253:
            return "Region descriptor must start after superblock offset='" + \
                    str(offset) + "'"
        format = '!QQQQBB'
        return RDTuple._make(struct.unpack(format,mymap[offset:offset+34]))

    def __init__(self,mymap,offset):
        self.data = self.setup(mymap,offset)
        self.myattrs = regiondesc_attrs.split(" ")

    def __getattr__(self,method_name):
        return getattr(self.data,method_name)

    def printme(self):
        for attr in self.myattrs:
            print attr + "=" + hex64(getattr(self.data,attr))

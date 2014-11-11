import mmap
import struct
from collections import namedtuple

from lib.helpers import *


class Region:

    def setup(self,mymap):
        if self.fsoffset+self.compressed_size > mymap.size():
            return "Trying to access past the end of the map: mymap.size='" + \
                   str(mymap.size()) + "' fsoffset+compressed_size='" + str(self.fsoffset+self.compressed_size) + "'"
        return mymap[self.fsoffset:self.fsoffset+self.compressed_size]

    def __init__(self,mymap,regiondesc):
        self.regiondesc = regiondesc
        self.data = self.setup(mymap)

    def __getattr__(self,method_name):
        return getattr(self.regiondesc,method_name)

    def printme(self):
        j=0
        h=""
        s=""
        for i in range(0,self.compressed_size):
            h += "%02X" % struct.unpack('!B',self.data[i:i+1])
            s += self.data[i]
            if j == 80:
                print h
                print s
                h=""
                s=""
                j=0
        print h
        print s

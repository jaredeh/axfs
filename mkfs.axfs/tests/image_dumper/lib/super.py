import mmap
import struct
from collections import namedtuple

from lib.helpers import *

superblock_attrs = 'magic signature digest cblock_size files size blocks'
superblock_attrs += ' mmap_size strings xip byte_aligned compressed node_type'
superblock_attrs += ' node_index cnode_offset cnode_index banode_offset'
superblock_attrs += ' cblock_offset inode_file_size inode_name_offset'
superblock_attrs += ' inode_num_entries inode_mode_index inode_array_index'
superblock_attrs += ' modes uids gids version_major version_minor version_sub'
superblock_attrs += ' compression_type timestamp page_shift'

SuperBlockTuple = namedtuple('SuperBlock', superblock_attrs)

class SuperBlock:

    def get_superblock(self,mymap):
        if 253 > mymap.size:
            print "Trying to access past the end of the map: map.size='" + \
                  str(mymap.size()) + "'"
            raise Exception
        format = '!I16s40sIQQQQQQQQQQQQQQQQQQQQQQBBBBQB'
        return SuperBlockTuple._make(struct.unpack(format, mymap[:253]))

    def __init__(self,mymap):
        self.data = self.get_superblock(mymap)
        self.myattrs = superblock_attrs.split(" ")

    def __getattr__(self,method_name):
        return getattr(self.data,method_name)

    def printme(self):
        print "magic=" + hex32(self.data.magic)
        print "signature='" + self.data.signature + "'"
        print "digest=" + hexme(self.data.digest,40)
        print "cblock_size=" + hex32(self.data.cblock_size)

        for attr in self.myattrs[4:26]:
            print attr + "=" + hex64(getattr(self.data,attr))

        for attr in self.myattrs[26:30]:
            print attr + "=" + hex8(getattr(self.data,attr))

        print "timestamp=" + hex64(self.data.timestamp)
        print "page_shift=" + str(self.data.page_shift)


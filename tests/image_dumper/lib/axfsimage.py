import mmap
import struct
from collections import namedtuple
from lib.super import *
from lib.descriptors import *
from lib.region import *
from lib.helpers import *
from lib.bytetable import *

ImageTuple = namedtuple('ImageData', 'sb descriptors strings xip byte_aligned\
                        compressed node_type node_index cnode_offset\
                        cnode_index banode_offset cblock_offset\
                        inode_file_size inode_name_offset inode_num_entries\
                        inode_mode_index inode_array_index modes uids gids')

class AxfsImage:
    def setup(self,mymap):
        sb = SuperBlock(mymap)
        descriptors = Descriptors(mymap)
        strings = Region(mymap,descriptors.strings)
        xip = Region(mymap,descriptors.xip)
        byte_aligned = Region(mymap,descriptors.byte_aligned)
        compressed = Region(mymap,descriptors.compressed)
        node_type = ByteTable(mymap,descriptors.node_type)
        node_index = ByteTable(mymap,descriptors.node_index)
        cnode_offset = ByteTable(mymap,descriptors.cnode_offset)
        cnode_index = ByteTable(mymap,descriptors.cnode_index)
        banode_offset = ByteTable(mymap,descriptors.banode_offset)
        cblock_offset = ByteTable(mymap,descriptors.cblock_offset)
        inode_file_size = ByteTable(mymap,descriptors.inode_file_size)
        inode_name_offset = ByteTable(mymap,descriptors.inode_name_offset)
        inode_num_entries = ByteTable(mymap,descriptors.inode_num_entries)
        inode_mode_index = ByteTable(mymap,descriptors.inode_mode_index)
        inode_array_index = ByteTable(mymap,descriptors.inode_array_index)
        modes = ByteTable(mymap,descriptors.modes)
        uids = ByteTable(mymap,descriptors.uids)
        gids = ByteTable(mymap,descriptors.gids)
        return ImageTuple._make([sb, descriptors, strings, xip, byte_aligned, compressed,
                                node_type, node_index, cnode_offset, cnode_index,
                                banode_offset, cblock_offset, inode_file_size,
                                inode_name_offset, inode_num_entries,
                                inode_mode_index, inode_array_index, modes, uids,
                                gids])

    def __init__(self,path):
        f = open(path, "r+")
        self.mymap = mmap.mmap(f.fileno(), 0)
        self.data = self.setup(self.mymap)

    def __del__(self):
        self.mymap.close()

    def __getattr__(self,method_name):
        return getattr(self.data,method_name)

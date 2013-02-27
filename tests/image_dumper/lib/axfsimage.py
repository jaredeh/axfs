import mmap
import struct
from collections import namedtuple
from lib.super import *
from lib.descriptors import *
from lib.region import *
from lib.helpers import *


ImageTuple = namedtuple('ImageData', 'sb descriptors strings xip byte_aligned\
                        compressed node_type node_index cnode_offset\
                        cnode_index banode_offset cblock_offset\
                        inode_file_size inode_name_offset inode_num_entries\
                        inode_mode_index inode_array_index modes uids gids')

class AxfsImage:
    def setup(self,map):
        sb = SuperBlock(map)
        descriptors = Descriptors(map)
        strings = Region(map,descriptors.strings)
        xip = Region(map,descriptors.xip)
        byte_aligned = Region(map,descriptors.byte_aligned)
        compressed = Region(map,descriptors.compressed)
        node_type = Region(map,descriptors.node_type)
        node_index = Region(map,descriptors.node_index)
        cnode_offset = Region(map,descriptors.cnode_offset)
        cnode_index = Region(map,descriptors.cnode_index)
        banode_offset = Region(map,descriptors.banode_offset)
        cblock_offset = Region(map,descriptors.cblock_offset)
        inode_file_size = Region(map,descriptors.inode_file_size)
        inode_name_offset = Region(map,descriptors.inode_name_offset)
        inode_num_entries = Region(map,descriptors.inode_num_entries)
        inode_mode_index = Region(map,descriptors.inode_mode_index)
        inode_array_index = Region(map,descriptors.inode_array_index)
        modes = Region(map,descriptors.modes)
        uids = Region(map,descriptors.uids)
        gids = Region(map,descriptors.gids)
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

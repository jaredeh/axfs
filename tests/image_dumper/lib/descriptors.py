import mmap
import struct
from collections import namedtuple
from lib.super import *
from lib.region_descriptor import *

DescriptorsTuple = namedtuple('DescriptorsData', 'strings xip byte_aligned compressed\
                        node_type node_index cnode_offset cnode_index\
                        banode_offset cblock_offset inode_file_size\
                        inode_name_offset inode_num_entries inode_mode_index\
                        inode_array_index modes uids gids')

class Descriptors:
    def setup(self,mymap):
        sb = SuperBlock(mymap)
        strings = RegionDescriptor(mymap,sb.strings)
        xip = RegionDescriptor(mymap,sb.xip)
        byte_aligned = RegionDescriptor(mymap,sb.byte_aligned)
        compressed = RegionDescriptor(mymap,sb.compressed)
        node_type = RegionDescriptor(mymap,sb.node_type)
        node_index = RegionDescriptor(mymap,sb.node_index)
        cnode_offset = RegionDescriptor(mymap,sb.cnode_offset)
        cnode_index = RegionDescriptor(mymap,sb.cnode_index)
        banode_offset = RegionDescriptor(mymap,sb.banode_offset)
        cblock_offset = RegionDescriptor(mymap,sb.cblock_offset)
        inode_file_size = RegionDescriptor(mymap,sb.inode_file_size)
        inode_name_offset = RegionDescriptor(mymap,sb.inode_name_offset)
        inode_num_entries = RegionDescriptor(mymap,sb.inode_num_entries)
        inode_mode_index = RegionDescriptor(mymap,sb.inode_mode_index)
        inode_array_index = RegionDescriptor(mymap,sb.inode_array_index)
        modes = RegionDescriptor(mymap,sb.modes)
        uids = RegionDescriptor(mymap,sb.uids)
        gids = RegionDescriptor(mymap,sb.gids)
        return DescriptorsTuple._make([strings, xip, byte_aligned, compressed,
                                node_type, node_index, cnode_offset, cnode_index,
                                banode_offset, cblock_offset, inode_file_size,
                                inode_name_offset, inode_num_entries,
                                inode_mode_index, inode_array_index, modes, uids,
                                gids])

    def __init__(self,mymap):
        self.data = self.setup(mymap)

    def __getattr__(self,method_name):
        return getattr(self.data,method_name)

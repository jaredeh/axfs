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
    def setup(self,map):
        sb = SuperBlock(map)
        strings = RegionDescriptor(map,sb.strings)
        xip = RegionDescriptor(map,sb.xip)
        byte_aligned = RegionDescriptor(map,sb.byte_aligned)
        compressed = RegionDescriptor(map,sb.compressed)
        node_type = RegionDescriptor(map,sb.node_type)
        node_index = RegionDescriptor(map,sb.node_index)
        cnode_offset = RegionDescriptor(map,sb.cnode_offset)
        cnode_index = RegionDescriptor(map,sb.cnode_index)
        banode_offset = RegionDescriptor(map,sb.banode_offset)
        cblock_offset = RegionDescriptor(map,sb.cblock_offset)
        inode_file_size = RegionDescriptor(map,sb.inode_file_size)
        inode_name_offset = RegionDescriptor(map,sb.inode_name_offset)
        inode_num_entries = RegionDescriptor(map,sb.inode_num_entries)
        inode_mode_index = RegionDescriptor(map,sb.inode_mode_index)
        inode_array_index = RegionDescriptor(map,sb.inode_array_index)
        modes = RegionDescriptor(map,sb.modes)
        uids = RegionDescriptor(map,sb.uids)
        gids = RegionDescriptor(map,sb.gids)
        return DescriptorsTuple._make([strings, xip, byte_aligned, compressed,
                                node_type, node_index, cnode_offset, cnode_index,
                                banode_offset, cblock_offset, inode_file_size,
                                inode_name_offset, inode_num_entries,
                                inode_mode_index, inode_array_index, modes, uids,
                                gids])

    def __init__(self,map):
        self.data = self.setup(map)

    def __getattr__(self,method_name):
        return getattr(self.data,method_name)

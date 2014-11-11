from lib.helpers import *
import os
import stat

XIP = 0
Compressed = 1
Byte_Aligned = 2


class Nodes:

    def do_xip_node(self,image,num):
        page_size = 1 << image.sb.page_shift
        off_start = page_size * num
        off_end = (num + 1) * page_size
        if (num + 1) > image.descriptors.xip.max_index:
            raise NameError("num={0} > image.descriptors.xip.max_index={1}".format(num,image.descriptors.xip.max_index))
        return image.xip.data[off_start:off_end]

    def do_cblock(self,image,num):
        import gzip, zlib
        off_start = image.cblock_offset[num]
        if (num + 1) > image.descriptors.cblock_offset.max_index:
            raise NameError("num={0} > image.descriptors.cblock_offset.max_index={1}".format(num,image.descriptors.cblock_offset.max_index))
        elif (num + 1) == image.descriptors.cblock_offset.max_index:
            off_end = image.descriptors.compressed.size
        else:
            off_end = image.cblock_offset[num+1]
        cblock = image.compressed.data[off_start:off_end]
        print "cblock='{0}' off_start={1} off_end={2}".format(cblock,off_start,off_end)
        ucblock = zlib.decompress(cblock)
        return ucblock

    def do_comp_node(self,image,num):
        cnode_index = image.cnode_index[num]
        ucblock = self.do_cblock(image,cnode_index)
        off_start = image.cnode_offset[num]
        if (num + 1) > image.descriptors.cnode_offset.max_index:
            raise NameError("num={0} > image.descriptors.cnode_offset.max_index={1}".format(num,image.descriptors.cnode_offset.max_index))
        elif (num + 1) == image.descriptors.cnode_offset.max_index:
            off_end = image.descriptors.cnode_offset.size
        else:
            off_end = image.cblock_offset[num+1]
        return ucblock[off_start:off_end]

    def do_ba_node(self,image,num):
        off_start = image.banode_offset[num]
        if (num + 1) > image.descriptors.byte_aligned.max_index:
            raise NameError("num={0} > image.descriptors.byte_aligned.max_index={1}".format(num,image.descriptors.byte_aligned.max_index))
        elif (num + 1) == image.descriptors.byte_aligned.max_index:
            off_end = image.descriptors.byte_aligned.size
        else:
            off_end = image.banode_offset[num+1]
        return image.byte_aligned.data[off_start:off_end]

    def do_node(self,image,num,d):
        node_type = image.node_type[num]
        node_index = image.node_index[num]
        if node_type == XIP:
            print ("  "*d)+"XIP"+str(node_index)
            return self.do_xip_node(image,node_index)
        elif node_type == Compressed:
            print ("  "*d)+"Compressed "+str(node_index)
            return self.do_comp_node(image,node_index)
        elif node_type == Byte_Aligned:
            print ("  "*d)+"Byte_Aligned"+str(node_index)
            return self.do_ba_node(image,node_index)

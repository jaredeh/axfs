import sys
from lib.axfsimage import *
from lib.inodes import *

image = AxfsImage(sys.argv[1])

image.sb.printme()

print "<-------strings::descriptors-------------->"
image.descriptors.strings.printme()
print "||------strings::data--------------------->"
image.strings.printme()

print "<-------xip::descriptors-------------->"
image.descriptors.xip.printme()
print "||------xip::data------------------------>"
image.xip.printme()

print "<-------byte_aligned::descriptors----------------->"
image.descriptors.byte_aligned.printme()
print "||------byte_aligned::data------------------------>"
#image.byte_aligned.printme()

print "<-------compressed::descriptors----------------->"
image.descriptors.compressed.printme()
print "||------compressed::data------------------------>"
image.compressed.printme()

print "<-------node_type::descriptors----------------->"
image.descriptors.node_type.printme()
print "||------node_type::data------------------------>"
image.node_type.printme()

print "<-------node_index::descriptors----------------->"
image.descriptors.node_index.printme()
print "||------node_index::data------------------------>"
image.node_index.printme()

print "<-------cnode_offset::descriptors----------------->"
image.descriptors.cnode_offset.printme()
print "||------cnode_offset::data------------------------>"
image.cnode_offset.printme()

print "<-------cnode_index::descriptors----------------->"
image.descriptors.cnode_index.printme()
print "||------cnode_index::data------------------------>"
image.cnode_index.printme()

print "<-------banode_offset::descriptors----------------->"
image.descriptors.banode_offset.printme()
print "||------banode_offset::data------------------------>"
image.banode_offset.printme()

print "<-------cblock_offset::descriptors----------------->"
image.descriptors.cblock_offset.printme()
print "||------cblock_offset::data------------------------>"
image.cblock_offset.printme()

print "<-------inode_file_size::descriptors--------->"
image.descriptors.inode_file_size.printme()
print "||------inode_file_size::data-------->"
image.inode_file_size.printme()

print "<-------inode_name_offset::descriptors--------->"
image.descriptors.inode_name_offset.printme()
print "||------inode_name_offset::data-------->"
image.inode_name_offset.printme()

print "<-------inode_num_entries::descriptors--------->"
image.descriptors.inode_num_entries.printme()
print "||------inode_num_entries::data-------->"
image.inode_num_entries.printme()

print "<-------inode_mode_index::descriptors----------------->"
image.descriptors.inode_mode_index.printme()
print "||------inode_mode_index::data------------------------>"
image.inode_mode_index.printme()

print "<-------inode_array_index::descriptors----------------->"
image.descriptors.inode_array_index.printme()
print "||------inode_array_index::data------------------------>"
image.inode_array_index.printme()

print "<-------modes::descriptors----------------->"
image.descriptors.modes.printme()
print "||------modes::data------------------------>"
image.modes.printme()

print "<-------uids::descriptors----------------->"
image.descriptors.uids.printme()
print "||------uids::data------------------------>"
image.uids.printme()

print "<-------gids::descriptors----------------->"
image.descriptors.gids.printme()
print "||------gids::data------------------------>"
image.gids.printme()


inodes = Inodes(image,"out")

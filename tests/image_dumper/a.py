import sys
from lib.axfsimage import *
from lib.inodes import *

image = AxfsImage(sys.argv[1])

image.sb.printme()

print "<-------descriptors-strings-------------->"
image.descriptors.strings.printme()
print "<-------descriptors-inode_name_index-------->"
image.descriptors.inode_name_index.printme()
print "<-------strings------------------------>"
image.strings.printme()
print "<-------xip------------------------>"
image.xip.printme()
print "<-------bytealigned------------------------>"
image.byte_aligned.printme()
print "<-------compressed------------------------>"
image.compressed.printme()
print "<-------node_type------------------------>"
print image.node_type[1]
image.node_type.printdata()
print "<-------mode------------------------>"
print image.modes.printdata()
print "<-------inode_mode_index------------------------>"
print image.inode_mode_index.printdata()
print "<-------descriptors-modes----------------->"
image.descriptors.modes.printme()
print "<-------mode------------------------>"
image.modes.printdata()
print "<-------descriptors-uids----------------->"
image.descriptors.uids.printme()
print "<-------uids------------------------>"
image.uids.printdata()
print "<-------descriptors-gids----------------->"
image.descriptors.gids.printme()
print "<-------gids------------------------>"
image.gids.printdata()
print "<-------cnode_offset------------------------>"
image.cnode_offset.printdata()
print "<-------cnode_index------------------------>"
image.cnode_index.printdata()
print "<-------cblock_offset------------------------>"
image.cblock_offset.printdata()

print "<-------descriptors-inode_array_index-------->"
image.descriptors.inode_array_index.printme()
print "<-------inode_array_index------------------------>"
image.inode_array_index.printdata()

print "<-------descriptors-banode_offset-------->"
image.descriptors.banode_offset.printme()
print "<-------banode_offset------------------------>"
image.banode_offset.printdata()
print "<-------descriptors-inode_name_offset-------->"
image.descriptors.inode_name_offset.printme()
print "<-------inode_name_offset-------->"
image.inode_name_offset.printdata()
print "<-------strings------------------------>"
image.strings.printme()

inodes = Inodes(image,"out")

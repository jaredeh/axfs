import sys
from lib.axfsimage import *
from lib.inodes import *

image = AxfsImage(sys.argv[1])

image.sb.printme()

print "<-------descriptors-strings-------------->"
image.descriptors.strings.printme()
print "<-------descriptors-inode_mode_index-------->"
image.descriptors.inode_mode_index.printme()
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
print image.node_type.printdata()
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

import stat
print stat.S_ISDIR(0x7fff)
print stat.S_ISDIR(0x41ed)
print stat.S_ISDIR(0x81a4)


inodes = Inodes(image,"out")

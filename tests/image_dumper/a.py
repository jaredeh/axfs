import mmap
import struct
from collections import namedtuple

from lib.super import *
from lib.helpers import *
from lib.region_descriptor import *
from lib.image import *

f = open("../../foo.bin", "r+")
map = mmap.mmap(f.fileno(), 0)

image = Image(map)

image.sb.printme()

image.strings.printme()


map.close()
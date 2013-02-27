from lib.axfsimage import *

image = AxfsImage("../../foo.bin")

image.sb.printme()

print "<------------------------------->"
image.descriptors.strings.printme()
print "<------------------------------->"
image.strings.printme()

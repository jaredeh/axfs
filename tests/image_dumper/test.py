import unittest
import os
from lib.axfsimage import *

class TestAxfsImageSimple(unittest.TestCase):

    def do_create_image(self,input_path,output,args):
        cmd = "../../mkfs.axfs -i "+input_path+" -o "+output+" "
        os.popen(cmd).read()
        return AxfsImage(output)

    def write_file(self,path,data):
        f = open(path,"wb")
        f.write(data)
        f.close()

    def make_simple_fs(self):
        os.system("rm -rf j")
        os.mkdir("j")
        os.mkdir("j/d")
        self.write_file("j/d/f","456")
        self.write_file("j/d/a","678")
        self.write_file("j/k","A"*162)

    def test_sanity(self):
        self.make_simple_fs()
        image = self.do_create_image("j","foo.bin","h")
        #print "<-------super------------------------------>"
        #image.sb.printme()
        #print "<-------descriptors------------------------>"
        #image.descriptors.strings.printme()
        #print "<-------strings---------------------------->"
        #image.strings.printme()
        #print "<-------xip-------------------------------->"
        #image.xip.printme()
        #print "<-------bytealigned------------------------>"
        #image.byte_aligned.printme()
        #print "<-------compressed------------------------->"
        #image.compressed.printme()
        #print "<------------------------------------------>"
        os.system("rm -rf j")

    def test_strings(self):
        self.make_simple_fs()
        image = self.do_create_image("j","foo.bin","h")
        d = image.strings.data
        self.assertEqual(len(d),5)
        self.assertIn(d[0],["d","f","a","k","\x00"])
        self.assertIn(d[1],["d","f","a","k","\x00"])
        self.assertIn(d[2],["d","f","a","k","\x00"])
        self.assertIn(d[3],["d","f","a","k","\x00"])
        self.assertIn(d[4],["d","f","a","k","\x00"])
        os.system("rm -rf j")

    def test_byte_aligned(self):
        self.make_simple_fs()
        image = self.do_create_image("j","foo.bin","h")
        d = image.byte_aligned.data
        self.assertEqual(len(d),6)
        self.assertIn(d,["456678","678456"])
        os.system("rm -rf j")

    def test_compressed(self):
        import gzip, zlib
        self.make_simple_fs()
        image = self.do_create_image("j","foo.bin","h")
        d = image.compressed.data
        self.assertTrue(len(d) > 10)
        self.assertTrue(len(d) < 160)
        self.assertEqual(zlib.decompress(d),"A"*162)
        os.system("rm -rf j")

    def test_xip(self):
        self.make_simple_fs()
        image = self.do_create_image("j","foo.bin","h")
        d = image.xip.data
        self.assertEqual(len(d),0)
        os.system("rm -rf j")

if __name__ == '__main__':
    unittest.main()
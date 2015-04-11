from lib.helpers import *
from lib.nodes import *
import os
import stat

'''
'''

class Inodes:

    def get_mode(self,image,num):
        mode_index = image.inode_mode_index[num]
        return image.modes[mode_index]

    def get_uid(self,image,num):
        mode_index = image.inode_mode_index[num]
        return image.uids[mode_index]

    def get_gid(self,image,num):
        mode_index = image.inode_mode_index[num]
        return image.gids[mode_index]

    def get_name(self,image,num,d):
        start_offset = image.inode_name_offset[num]
        max_num = image.descriptors.inode_name_offset.max_index
        if max_num == (num+1):
            end_offset = image.descriptors.strings.size
        elif (num+1) > max_num:
            raise NameError("inode_name_offset max="+str(max_num)+" num="+str(num))
        else:
            end_offset = image.inode_name_offset[num+1]
        print ("  "*d)+"--name={0} num={1} start={2} end={3}".format(image.strings.data[start_offset:end_offset],num,start_offset,end_offset)
        return image.strings.data[start_offset:end_offset]

    def get_file_data(self,image,i,d):
        return self.nodes.do_node(image,i,d)

    def do_inode(self,image,num,d=-1):
        d += 1
        name = self.get_name(image,num,d)
        mode = self.get_mode(image,num)
        entries = image.inode_num_entries[num]
        uid = self.get_uid(image,num)
        gid = self.get_gid(image,num)
        array_index = image.inode_array_index[num]
        max_num = image.descriptors.inode_array_index.max_index
#        print "name={0} mode={1} entries={2} uid={3} gid={4} array_index={5} max_num={6}".format(name,mode,entries,uid,gid,array_index,max_num)
        if stat.S_ISDIR(mode):
            print ("  "*d)+"dir={0} num={1} entries={2} uid={3} gid={4} array_index={5} max_num={6} mode={7}".format(name,num,entries,uid,gid,array_index,max_num,mode)
            os.mkdir(name)
            os.chdir(name)
            for i in range(array_index,array_index+entries):
                self.do_inode(image,i,d)
            os.chdir("..")
        elif num == 0:
            print ("  "*d)+"root={0} num={1} entries={2} uid={3} gid={4} array_index={5} max_num={6} mode={7}".format(name,num,entries,uid,gid,array_index,max_num,mode)
            for i in range(1,entries+1):
                self.do_inode(image,num+i,d)
        else:
            print ("  "*d)+"filename={0} num={1} entries={2} uid={3} gid={4} array_index={5} max_num={6} mode={7}".format(name,num,entries,uid,gid,array_index,max_num,mode)
            f = open(name,"wb")
            for i in range(array_index,array_index+entries):
                d = self.get_file_data(image,i,d)
                f.write(d)
            f.close
        #os.chmod(name,mode)
        #os.chown(name,uid,gid)

    def __init__(self,image,dir_name):
        self.nodes = Nodes()
        os.mkdir(dir_name)
        os.chdir(dir_name)
        self.do_inode(image,0)
        os.chdir("..")




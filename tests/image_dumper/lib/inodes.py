from lib.helpers import *
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

    def get_name(self,image,num):
        start_offset = image.inode_name_offset[num]
        max_num = image.descriptors.inode_name_offset.max_index
        if max_num == num:
            end_offset = image.descriptors.inode_name_offset.size
        elif num > max_num:
            raise NameError("inode_name_offset max="+str(max_num)+" num="+str(num))
        else:
            end_offset = image.inode_name_offset[num+1]
        return image.strings.data[start_offset:end_offset]

    def get_file_data(self,image,i):
        return "A"*4096

    def do_inode(self,image,num):
        name = self.get_name(image,num)
        mode = self.get_mode(image,num)
        entries = image.inode_num_entries[num]
        uid = self.get_uid(image,num)
        gid = self.get_gid(image,num)
        array_index = image.inode_array_index[num]
        max_num = image.descriptors.inode_array_index.max_index
        print "name={0} mode={1} entries={2} uid={3} gid={4} array_index={5} max_num={6}".format(name,mode,entries,uid,gid,array_index,max_num)
        if stat.S_ISDIR(mode):
            print "name={0} is dir".format(name)
            os.mkdir(name)
            os.chdir(name)
            for i in range(1,entries+1):
                self.do_inode(image,num+i)
            os.chdir("..")
        elif num == 0:
            for i in range(1,entries+1):
                self.do_inode(image,num+i)
        else:
            print name
            f = open(name,"wb")
            for i in range(array_index,array_index+entries):
                d = self.get_file_data(image,i)
                f.write(d)
            f.close
        #os.chmod(name,mode)
        #os.chown(name,uid,gid)

    def __init__(self,image,dir_name):
        os.mkdir(dir_name)
        os.chdir(dir_name)
        self.do_inode(image,0)
        os.chdir("..")




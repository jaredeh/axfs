cd /opt/poky/
for ARCH in arm mips ppc x86 x86-64
do
  cd $ARCH
  if ! [ -f hdb.ext2 ]
    then
      sudo fallocate -l 10000000000 hdb.ext2
      sudo mkfs.ext2 -F hdb.ext2
      sudo mount -o loop hda.ext2 mnt
      ruby -e 'puts "/dev/disk/by-uuid/" + `blkid hdb.ext2`.split("\"")[1] + "\t/home/root\text2\trw,defaults\t0 0"' | sudo tee -a mnt/etc/fstab
      sudo umount mnt
  fi
  sudo mount -o loop hdb.ext2 mnt
  cd mnt
  sudo rm -rf kernel_git
  sudo cp -r /opt/git/linux/.git kernel_git
  cd ..
  sudo umount mnt
  cd ..
done
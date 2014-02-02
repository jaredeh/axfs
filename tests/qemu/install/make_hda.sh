cd /opt/poky/
for ARCH in arm mips ppc x86 x86-64
do
  mkdir -p $ARCH
  cd $ARCH
  wget http://downloads.yoctoproject.org/releases/yocto/yocto-1.4.2/machines/qemu/qemu$ARCH/core-image-lsb-sdk-qemu$ARCH.tar.bz2
  #cp /home/jared/projects/axfs/qemu/yocto/$ARCH/core-image-lsb-sdk-qemu$ARCH.tar.bz2 .
  mkdir -p mnt
  sudo rm -rf hda.ext2
  sudo fallocate -l 5000000000 hda.ext2
  sudo mkfs.ext2 -F hda.ext2
  sudo mount -o loop hda.ext2 mnt
  cd mnt
  sudo tar xvjf ../core-image-lsb-sdk-qemu$ARCH.tar.bz2
  cd ..
  sudo umount mnt
  cd ..
done

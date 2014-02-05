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

cd /opt/poky/arm/
wget http://downloads.yoctoproject.org/releases/yocto/yocto-1.4.2/machines/qemu/qemuarm/zImage-qemuarm.bin
cd /opt/poky/mips/
wget http://downloads.yoctoproject.org/releases/yocto/yocto-1.4.2/machines/qemu/qemumips/vmlinux-qemumips.bin
cd /opt/poky/ppc/
wget http://downloads.yoctoproject.org/releases/yocto/yocto-1.4.2/machines/qemu/qemuppc/vmlinux-qemuppc.bin
cd /opt/poky/x86/
wget http://downloads.yoctoproject.org/releases/yocto/yocto-1.4.2/machines/qemu/qemux86/bzImage-qemux86.bin
cd /opt/poky/x86-64/
wget http://downloads.yoctoproject.org/releases/yocto/yocto-1.4.2/machines/qemu/qemux86-64/bzImage-qemux86-64.bin



sudo apt-get -y install gawk wget git-core diffstat unzip texinfo gcc-multilib build-essential chrpath libsdl1.2-dev xterm
git clone git://git.yoctoproject.org/poky.git
cd poky
git checkout dylan
source oe-init-build-env
bitbake core-image-minimal
pwd
sudo mkdir -p /opt/poky
sudo chmod a+w /opt/poky
mv tmp/sysroots/x86_64-linux/usr/ /opt/poky/

## apt-get install openbios-ppc
## apt-get install openhackware
## apt-get install ipxe

export QEMU_PORT=5511
mkdir -p /opt/poky/src
wget -P /opt/poky/src ftp://ftp.gnu.org/gnu/classpath/classpath-0.98.tar.gz
scp -P $QEMU_PORT /opt/poky/src/classpath-0.98.tar.gz root@localhost:~
ssh -p $QEMU_PORT root@localhost "tar zxvf classpath-0.98.tar.gz; cd classpath-0.98; ./configure --disable-gtk-peer --disable-gconf-peer --disable-plugin --disable-Werror  --with-ecj-jar=~/ecj-4.3.1.jar"

mkdir -p /opt/poky/src
wget -P /opt/poky/src https://github.com/kaffe/kaffe/archive/master.zip
mv /opt/poky/src/master.zip /opt/poky/src/kaffe.zip

export QEMU_PORT=5511
mkdir -p /opt/poky/src
wget -P /opt/poky/src http://downloads.sourceforge.net/project/jamvm/jamvm/JamVM%201.5.4/jamvm-1.5.4.tar.gz
scp -P $QEMU_PORT /opt/poky/src/jamvm-1.5.4.tar.gz root@localhost:~
ssh -p $QEMU_PORT root@localhost "tar zxvf jamvm-1.5.4.tar.gz; cd jamvm-1.5.4; ./configure; make; make install prefix=/usr/local"

mkdir -p /opt/poky/src
wget -P /opt/poky/src  http://carroll.aset.psu.edu/pub/eclipse/eclipse/downloads/drops4/R-4.3.1-201309111000/ecj-4.3.1.jar
scp -P $QEMU_PORT /opt/poky/src/ecj-4.3.1.jar root@localhost:~

wget -P /opt/poky/src http://downloads.sourceforge.net/project/jikes/Jikes/1.22/jikes-1.22.tar.bz2
scp -P $QEMU_PORT /opt/poky/src/jikes-1.22.tar.bz2 root@localhost:~

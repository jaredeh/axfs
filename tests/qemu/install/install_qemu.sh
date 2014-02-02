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

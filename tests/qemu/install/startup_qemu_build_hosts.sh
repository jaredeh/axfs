for ARCH in arm mips ppc x86 x86-64
do
  cp tests/qemu/run_emu/$ARCH/run_emu.rb /opt/poky/$ARCH/
  sudo screen -S build_$ARCH -d -m ruby -C /opt/poky/$ARCH/ ./run_emu.rb
  sleep 10
done
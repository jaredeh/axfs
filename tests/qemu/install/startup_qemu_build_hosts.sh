for ARCH in arm mips ppc x86 x86-64
do
  cp tests/qemu/run_emu/$ARCH/run_emu.rb /opt/poky/$ARCH/
done

for ARCH in arm mips ppc x86 x86-64
do
  cd /opt/poky/$ARCH/
  ruby ./run_emu.rb > go.sh
  chmod +x go.sh
  echo $EMU_CMD
  screen -S build_$ARCH -d -m sudo ./go.sh
  sleep 60
done
arch = "arm"
port = "5555"

qemu_system_binary = "qemu-system-" + arch
qemu_extra = "-m 256 -nographic -no-reboot -M versatilepb -device smc91c111,netdev=user.0 -netdev user,id=user.0,hostfwd=tcp::#{port}-:22"
append = "root=\"0800\" rw init=/sbin/init.sh panic=1 console=ttyAMA0"

a={}
a["kernel"] = "zImage-qemuarm.bin"
a["hda"] = "hda.ext2"
a["hdb"] = "hdb.ext2"
a[:KERNEL_APPEND] = append
a[:QEMU_EXTRA] = qemu_extra
a[:QEMU_BINARY] = qemu_system_binary

def run_emulator(parameter)
  cmd  = parameter[:QEMU_BINARY]
  parameter.keys.each do |key|
    if not key.is_a?(String)
      next
    end
    cmd += " -#{key} #{parameter[key]}"
  end
  cmd += " -append \"" + parameter[:KERNEL_APPEND] + "\""
  cmd += " " + parameter[:QEMU_EXTRA]
  if parameter["hda"] != nil
    cmd += " -hda " + parameter["hda"]
  end
  if parameter["hdb"] != nil
    cmd += " -hdb " + parameter["hdb"]
  end
  puts cmd
  `#{cmd}`
end

run_emulator(a)


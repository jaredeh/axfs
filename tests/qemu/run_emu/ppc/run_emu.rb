arch = "ppc"
port = "5533"

qemu_system_binary = "/opt/poky/usr/bin/qemu-system-" + arch
qemu_extra = "-m 256 -nographic -no-reboot -redir tcp:#{port}::22"
append = "root=/dev/hda rw init=/sbin/init.sh panic=1 console=ttyS0"

a={}
a["kernel"] = "vmlinux"
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
  puts cmd
end

run_emulator(a)


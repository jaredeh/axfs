def run(cmd)
  pid, stdin, stdout, stderr = Open4::popen4 "bash"
  stdin.puts cmd
  stdin.close
  puts "cmd        : #{ cmd }"
  puts "pid        : #{ pid }"
  ignored, status = Process::waitpid2 pid
  puts "stdout     : #{ stdout.read.strip }"
  puts "stderr     : #{ stderr.read.strip }"
  puts "status     : #{ status.inspect }"
  puts "exitstatus : #{ status.exitstatus }"
  puts "================================================================"
  if status.exitstatus != 0
    raise
  end
end

def build(options)
  if not File.exists?(options[:kernel])
    run "git clone --no-checkout --reference /opt/linux_git https://github.com/torvalds/linux.git #{options[:kernel]}"
  end
  startdir = Dir.pwd
  Dir.chdir options[:kernel]
  run "git checkout -f #{options[:kernel]}"
  run "rm ../build.log"
  run "make mrproper"
  if options[:patch]
    run "perl ../../tools/patchin.pl --assume-yes --link"
  end
  if options[:config]
    run "make defconfig"
    run "echo \"CONFIG_AXFS=#{options[:config]}\" >> .config"
    if options[:profiling]
      run "echo \"CONFIG_AXFS_PROFILING=#{options[:profiling]}\" >> .config"
    end
    run "make silentoldconfig"
  elsif options[:build]
    run "make defconfig"
  end
  if options[:build]
    run "make -j 2 2>&1 | tee ../build.log;"
  end
  Dir.chdir startdir
end

require 'optparse'
require 'open4'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: make_kernel.rb [options]"

  opts.on("-k", "--kernel VERSION", String, "Kernel version") do |o|
    options[:kernel] = o
  end

  opts.on("-c", "--config TYPE", ['y', 'm'], "AXFS Kconfig options build type, 'y' for builtin, 'm' for module") do |o|
    options[:config] = o
  end

  opts.on("-p", "--profiling","Enable profiling") do |o|
    options[:profiling] = 'y'
  end

  opts.on("-b", "--build","Do build") do |o|
    options[:build] = o
  end

  opts.on("-t", "--patch","Patch in AXFS code") do |o|
    options[:patch] = o
  end

end.parse!

if not options[:kernel]
  raise "-k or --kernel required"
end

`mkdir -p linux`
Dir.chdir File.join(File.dirname(__FILE__),"linux")
puts options
puts Dir.pwd
build(options)

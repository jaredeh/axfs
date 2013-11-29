kernels = [
  "v2.6.25",
  "v2.6.26",
  "v2.6.27",
  "v2.6.28",
  "v2.6.29",
  "v2.6.30",
  "v2.6.31",
  "v2.6.32",
  "v2.6.33",
  "v2.6.34",
  "v2.6.35",
  "v2.6.36",
  "v2.6.37",
  "v2.6.38",
  "v2.6.39",
  "v3.0",
  "v3.1",
  "v3.2",
  "v3.3",
  "v3.4",
  "v3.5",
  "v3.6",
  "v3.7",
  "v3.8",
  "v3.9",
  "v3.10",
  "v3.11",
  "v3.12"
]

def run(cmd)
  puts cmd
  pid, stdin, stdout, stderr = Open4::popen4 "bash"
  stdin.puts cmd
  stdin.close
  ignored, status = Process::waitpid2 pid

  puts "pid        : #{ pid }"
  puts "stdout     : #{ stdout.read.strip }"
  puts "stderr     : #{ stderr.read.strip }"
  puts "status     : #{ status.inspect }"
  puts "exitstatus : #{ status.exitstatus }"

end

def build(options)
  k = options[:kernel]
  if not File.exists?(options[:kernel])
    run "git clone --no-checkout --reference /opt/linux_git https://github.com/torvalds/linux.git #{options[:kernel]}"
  end
  Dir.chdir options[:kernel]
  run "git checkout -f #{options[:kernel]}"
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
    run "make -j 9; make"
  end
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

  opts.on("-t", "--patch","Patch in AXFS code") do |o|
    options[:patch] = o
  end


end.parse!

if not options[:kernel]
  raise "-k or --kernel required"
end

Dir.chdir File.join(File.dirname(__FILE__),"linux")
puts options
puts Dir.pwd
build(options)
STDOUT.sync = true
STDERR.sync = true


def run(cmd)
  puts "cmd        : #{ cmd }"
  puts `#{cmd} 2>&1`
  status = $?
  puts "exitstatus : #{ status.exitstatus }"
  puts "================================================================"
  if status.exitstatus != 0
    raise
  end
end

def kernel_version(options)
  ka = options[:kernel].split('v')[1].split('.')
  kernelversion  = ka[0].to_i * 1000
  kernelversion += ka[1].to_i * 100
  kernelversion += ka[2].to_i
  return kernelversion
end

def test_config(query)
  resp = `grep "#{query}" .config`.chomp
  puts "looked for '#{query}' found '#{resp}'"
  if not resp == query
    raise "#{query} not found"
  end
end

def build(options)
  if kernel_version(options) < 2627
    opt = "ARCH=i386"
  else
    opt = ""
  end
  if not File.exists?(options[:kernel])
    run "git clone --no-checkout --reference /opt/linux_git https://github.com/torvalds/linux.git #{options[:kernel]}"
  end
  startdir = Dir.pwd
  Dir.chdir options[:kernel]
  run "git checkout -f #{options[:kernel]}"
  run "rm -f ../build.log"
  run "make mrproper"
  run "perl ../../../tools/patchin.pl --stock"
  if options[:patch]
    run "perl ../../../tools/patchin.pl --assume-yes --link"
  end
  run "make #{opt} defconfig"
  if options[:config]
    run "echo \"CONFIG_AXFS=#{options[:config]}\" >> .config"
    if options[:profiling] == 'N'
      run "echo \"# CONFIG_AXFS_PROFILING is not set\" >> .config"
    else
      run "echo \"CONFIG_AXFS_PROFILING=#{options[:profiling]}\" >> .config"
    end
    run "make #{opt} silentoldconfig"
    test_config "CONFIG_AXFS=#{options[:config]}"
    if options[:profiling] == 'N'
      test_config "# CONFIG_AXFS_PROFILING is not set"
    else
      test_config "CONFIG_AXFS_PROFILING=#{options[:profiling]}"
    end
  end
  if options[:build]
    run "make #{opt}"
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
    if not options[:profiling]
      options[:profiling] = 'N'
    end
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

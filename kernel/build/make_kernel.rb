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

def patch_config(old_txt,new_txt)
  run "mv .config .config.old; cat .config.old | sed 's/#{old_txt}/#{new_txt}/' >> .config; rm .config.old"
end

def build(options)
  if kernel_version(options) < 2627 and kernel_version(options) != 2612
    opt = "ARCH=i386"
  else
    opt = ""
  end
  startdir = Dir.pwd
  if not File.exists?(options[:kernel])
    run "git clone --no-checkout --reference /opt/git/linux /opt/git/linux #{options[:kernel]}"
    Dir.chdir options[:kernel]
    run "git checkout -f #{options[:kernel]}"
    run "make mrproper"
    run "perl ../../../tools/patchin.pl --stock"
    if options[:patch]
      run "perl ../../../tools/patchin.pl --assume-yes --link"
    end
    run "make #{opt} defconfig"
    if options[:mtd]
      old_txt = "# CONFIG_MTD is not set"
      new_txt = "CONFIG_MTD=y"
      patch_config(old_txt,new_txt)
      run "yes \"\" | make #{opt} oldconfig"
      test_config "CONFIG_MTD=y"
    end
    if options[:config]
      old_txt = "# CONFIG_AXFS is not set"
      new_txt = "CONFIG_AXFS=#{options[:config]}"
      if options[:profiling] == 'N'
        new_txt += "\\n# CONFIG_AXFS_PROFILING is not set"
      else
        new_txt += "\\nCONFIG_AXFS_PROFILING=#{options[:profiling]}"
      end
      patch_config(old_txt,new_txt)
      run "yes \"\" | make #{opt} oldconfig"
      test_config "CONFIG_AXFS=#{options[:config]}"
      if options[:profiling] == 'N'
        test_config "# CONFIG_AXFS_PROFILING is not set"
      else
        test_config "CONFIG_AXFS_PROFILING=#{options[:profiling]}"
      end
    end
  end
  if options[:build]
    if options[:no_cleanup]
      run "rm -f fs/axfs/*.o"
    end
    run "make #{opt}"
  end
  Dir.chdir startdir
end

def cleanup(options)
  if not options[:no_cleanup]
    run "rm -rf linux"
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
    if not options[:profiling]
      options[:profiling] = 'N'
    end
  end

  opts.on("-m", "--mtd","Enable MTD") do |o|
    options[:mtd] = 'y'
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

  opts.on("-n", "--no_cleanup","Don't cleanup files") do |o|
    options[:no_cleanup] = o
  end

end.parse!

if not options[:kernel]
  raise "-k or --kernel required"
end

d = Dir.pwd
begin
  `mkdir -p linux`
  Dir.chdir File.join(File.dirname(__FILE__),"linux")
  puts options
  puts Dir.pwd
  build(options)
  Dir.chdir d
  cleanup(options)
rescue Exception => e
  puts "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
  puts "  failed - cleaning up"
  Dir.chdir d
  puts Dir.pwd
  cleanup(options)
  raise e
end

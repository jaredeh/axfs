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

def kconfig_opts(key,value,options)
  old_txt = "# #{key} is not set"
  new_txt = "#{key}=#{value}"
  if key == "CONFIG_AXFS" and ['n','N'].include?(value)
    if not options[:config]["CONFIG_AXFS_PROFILING"]
      new_txt += "\\n# CONFIG_AXFS_PROFILING is not set"
    end
  end
  patch_config(old_txt,new_txt)
  run "yes \"\" | make #{options[:buildopt]} oldconfig"
  test_config "#{key}=#{value}"
end

def build(options)
  if kernel_version(options) < 2627 and kernel_version(options) != 2612
    options[:buildopt] = "ARCH=i386"
  else
    options[:buildopt] = ""
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
    run "make #{options[:buildopt]} defconfig"

    options[:config].each do |key,value|
      kconfig_opts(key,value,options)
    end
  end
  if options[:build]
    if options[:no_cleanup]
      run "rm -f fs/axfs/*.o"
    end
    run "make #{options[:buildopt]}"
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

  opts.on("-c", "--config CONFIGS", String, "Kconfig options CONFIG_PANCAKES=y => PANCAKES=y or PANCAKES=m.  Multiple options PANCAKES=y,PROFILING=y.") do |o|
    options[:config] = Hash.new
    o.split(',').each do |configline|
      config = configline.split('=')[0]
      configopt = configline.split('=')[1]
      if configopt == nil
        raise
      end
      options[:config]["CONFIG_"+config] = configopt
    end
    
    puts options[:config]

  end

  opts.on("-b", "--build","Do build") do |o|
    options[:build] = o
  end

  opts.on("-t", "--patch","Patch in AXFS code") do |o|
    options[:patch] = o
  end

  opts.on("-r", "--rebuild","Don't cleanup files") do |o|
    options[:rebuild] = o
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

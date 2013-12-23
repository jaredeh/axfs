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

def test_config(query,fail=true)
  resp = `grep "#{query}" .config`.chomp
  puts "looked for '#{query}' found '#{resp}'"
  if not resp == query
    if fail
      raise "#{query} not found"
    end
    return false
  end
  return true
end

def patch_config(old_txt,new_txt)
  run "mv .config .config.old; cat .config.old | sed 's/#{old_txt}/#{new_txt}/' >> .config; rm .config.old"
end

def unset_kconfig_opt(key,options)
  old_txt = "#{key}=y"
  new_txt = "# #{key} is not set"
  patch_config(old_txt,new_txt)
  run "yes \"\" | make #{options[:buildopt]} oldconfig"
  old_txt = "#{key}=m"
  patch_config(old_txt,new_txt)
  run "yes \"\" | make #{options[:buildopt]} oldconfig"
  if test_config("# #{key} is not set",false)
    return
  elsif test_config("#{key}=y",false) or test_config("#{key}=m",false)
    raise "#{query} not found"
  end
end

def set_kconfig_opt(key,value,new_txt,options)
  old_txt = "# #{key} is not set"
  patch_config(old_txt,new_txt)
  run "yes \"\" | make #{options[:buildopt]} oldconfig"
  test_config "#{key}=#{value}"
end

def kconfig_opts(key,value,options)
  if ['n','N'].include?(value)
    unset_kconfig_opt(key,options)
  else
    new_txt = "#{key}=#{value}"
    if key == "CONFIG_AXFS"
      if not options[:config]["CONFIG_AXFS_PROFILING"] = 'y'
        new_txt += "\\n# CONFIG_AXFS_PROFILING is not set"
      end
    end
    set_kconfig_opt(key,value,new_txt,options)
  end
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
  else
    Dir.chdir options[:kernel]
  end
  if options[:build]
    if options[:rebuild]
      run "rm -f fs/axfs/*.o"
    end
    run "make #{options[:buildopt]}"
  end
  Dir.chdir startdir
end

def cleanup(options)
  if not options[:rebuild]
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

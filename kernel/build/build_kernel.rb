STDOUT.sync = true
STDERR.sync = true


def run(cmd)
  puts "cmd        : #{ cmd }"
  out = `#{cmd} 2>&1`
  puts out
  status = $?
  puts "exitstatus : #{ status.exitstatus }"
  puts "================================================================"
  if status.exitstatus != 0
    raise "exitstatus != 0"
  end
  return out
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
    raise "#{key} found"
  end
end

def set_kconfig_opt(key,value,options,new_txt="")
  if new_txt == ""
    new_txt = "#{key}=#{value}"
  end
  old_txt = "# #{key} is not set"
  patch_config(old_txt,new_txt)
  run "yes \"\" | make #{options[:buildopt]} oldconfig"
  test_config "#{key}=#{value}"
end

def kconfig_opts(key,value,options)
  if ['n','N'].include?(value)
    if key == "CONFIG_BLOCK"
      set_kconfig_opt("CONFIG_EMBEDDED","y",options)
    end
    unset_kconfig_opt(key,options)
  else
    if key == "CONFIG_AXFS"
      new_txt = "#{key}=#{value}"
      if not options[:config]["CONFIG_AXFS_PROFILING"] = 'y'
        new_txt += "\\n# CONFIG_AXFS_PROFILING is not set"
      end
      set_kconfig_opt(key,value,options,new_txt)
    else
      set_kconfig_opt(key,value,options)
    end
  end
end

def check_for_warnings(txt)
  fail = false
  txt.split('\n').each do |l|
    if l =~ /[Ww]arning/
      fail = true
    elsif l =~ /[Ee]rror/
      if not l =~ /error.o/
        fail = true
      end
    end
  end
  if fail
    raise "Warning/Error: '#{l}'"
  end
end

def build(options)
  if kernel_version(options) < 2627 and kernel_version(options) != 2612
    options[:buildopt] = " ARCH=i386"
  else
    options[:buildopt] = ""
  end
  if options[:uml]
    options[:buildopt] += " ARCH=um"
  end
  startdir = Dir.pwd
  if not File.exists?(options[:kernel])
    run "git clone --no-checkout --reference #{options[:repo]} #{options[:repo]} #{options[:kernel]}"
    options[:mrproper] = true
  end
  Dir.chdir options[:kernel]
  if options[:mrproper]
    run "git checkout -f #{options[:kernel]}"
    run "make mrproper"
    run "ruby ../../../tools/patchin.rb --stock"
    if options[:patch]
      run "ruby ../../../tools/patchin.rb --assume-yes --link"
    end
    run "make #{options[:buildopt]} defconfig"

    options[:config].each do |key,value|
      kconfig_opts(key,value,options)
    end
  end
  if options[:build]
    run "rm -f fs/axfs/*.o"
    output = run "make #{options[:buildopt]}"
    check_for_warnings(output)
  end
  Dir.chdir startdir
end

def cleanup(options)
  if options[:wipe]
    run "rm -rf linux"
  end
end

require 'optparse'
require 'open4'

options = {}
options[:config] = Hash.new
OptionParser.new do |opts|
  opts.banner = "Usage: make_kernel.rb [options]"

  opts.on("-k", "--kernel VERSION", String, "Kernel version") do |o|
    options[:kernel] = o
  end

  opts.on("-r", "--repo SOURCE", String, "Kernel source code repo") do |o|
    options[:repo] = o
  end

  opts.on("-c", "--config CONFIGS", String, "Kconfig options CONFIG_PANCAKES=y => PANCAKES=y or PANCAKES=m.  Multiple options PANCAKES=y,PROFILING=y.") do |o|
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

  opts.on("-u", "--uml=y/n",['y','n'],"Do uml build") do |o|
    if o == 'y'
      options[:uml] = true
    else o == 'n'
      options[:uml] = false
    end
  end

  opts.on("-t", "--patch","Patch in AXFS code") do |o|
    options[:patch] = o
  end

  opts.on("-m", "--mrproper","Do a make mrproper") do |o|
    options[:mrproper] = o
  end

  opts.on("-w", "--wipe","Like we were never here") do |o|
    options[:wipe] = o
  end

  opts.on("-N", "--null","fake makes jenkins integration easier") do |o|
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

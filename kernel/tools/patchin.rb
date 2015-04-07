#!/usr/bin/ruby
require 'fileutils'
require "pp"

def get_kernel_version(config)
  file = File.join("/",config[:path],"Makefile")
  if not File.file?(file) then raise "#{config[:path]} not a valid kernel directory." end
  lines = File.readlines(file)
  config[:majver] = lines[0].split(" ")[2]
  config[:minver] = lines[1].split(" ")[2]
  config[:subver] = lines[2].split(" ")[2]
  if (config[:subver] == "0")
    config[:kernelver] = "v" + config[:majver] + "." + config[:minver]
  else
    config[:kernelver] = "v" + config[:majver] + "." + config[:minver] + "." + config[:subver]
  end
end

def print_help
  puts "Patchin Script"
  puts ""
  puts "Usage: patchin.rb [OPTION] [PATH]"
  puts " --copy			Add via copy. [default: use symlinks]"
  puts " --none			Skip AXFS files, patches only."
  puts " --stock			Apply patches we've added to fix older kernels build with newer tools. Then quit."
  puts " --assume-yes		Assume yes to all questions [default: ask user]"
  puts " --pretend		Don't apply any changes, just pretend you're going to."
  puts ""
  puts "[PATH] should point to a kernel directory, otherwise the current"
  puts "working directory will be assumed to be the desired kernel directory"
end

def parse_args()
  config = {}
  config[:cwd] = Dir.getwd
  config[:base] = File.expand_path(File.dirname(__FILE__))
  config[:majver ]= 1
  config[:minver] = 1
  config[:subver] = 1
  config[:kernelver] = ""

  config[:insert_type] = "link"
  config[:path] = config[:cwd]
  config[:assume_yes] = false
  config[:stock] = false
  config[:pretend] = false


  ARGV.each do |arg|
    if (arg == "--copy")
      config[:insert_type] = "copy"
    elsif (arg == "--none")
      config[:insert_type] = "none"
    elsif (arg == "--help")
      print_help()
      exit
    elsif (arg == "--assume-yes")
      config[:assume_yes] = true
    elsif (arg == "--stock")
      config[:stock] = true
    elsif (arg == "--pretend")
      config[:pretend] = true
    elsif (arg =~ /^[~|\/|\.|\w].*/)
      config[:path] = arg
    else
      raise "don't know option #{arg}"
    end
  end

  get_kernel_version(config)

  config
end

def select_files(path)
  files = []
  Dir.entries(path).each do |f|
    file = File.join(path,f)
    if not File.file?(file) then next end
    files.push(f)
  end
  files
end

def patch_kernel(config,in_path)
  base_path = File.expand_path(File.join(config[:base],"..",in_path))
  if not File.directory?(base_path) then raise "Invalid directory - #{base_path}" end
  path = File.join(base_path,config[:kernelver])
  if not File.directory?(path)
    puts "nothing to patch for #{config[:kernelver]}"
    return
  end
  select_files(path).each do |patch|
    cmd = "patch -p1 -i #{File.join(path,patch)} -d #{config[:path]}"
    if config[:pretend] then cmd += " --dry-run" end
    puts "Applying patch - #{patch}"
    #puts "cmd: \"#{cmd}\""
    if not system(cmd)
      raise "cmd: \"#{cmd}\" failed with #{$?}"
    end
  end
end

def insert_files(config,in_path)
  srcdir = File.expand_path(File.join(config[:base],"..",in_path))
  if not File.directory?(srcdir) then raise "Invalid directory - #{srcdir}" end
  dstdir = File.expand_path(File.join(config[:path],in_path))
  if not config[:pretend]
    FileUtils.mkdir_p(dstdir)
  end
  select_files(srcdir).each do |f|
    srcfile = File.join(srcdir,f)
    dstfile = File.join(dstdir,f)
    puts "Inserting #{f} via #{config[:insert_type]}"
    if config[:pretend] then next end
    if config[:insert_type] == "link"
      FileUtils.ln_s(srcfile,dstfile)
    else
      FileUtils.cp(srcfile,dstfile)
    end
  end
end

def insert_line(config,path,tokens,newline)
  file = File.join(config[:path],path)
  if not File.file?(file) then raise "#{file} missing - not a valid kernel directory." end
  filedata = File.read(file)
  token = ""
  tokens.each do |t|
    if filedata =~ /#{t}/
      token = t
      break
    end
  end
  if token == "" then raise "couldn't find tokens #{tokens.join(",")} in #{file}" end
  newdata = []
  filedata.split("\n").each do |line|
    newdata.push(line)
    if line =~ /#{token}/
      puts "Inserting \"#{newline}\" after \"#{line}\""
      newdata.push(newline)
    end
  end
  if config[:pretend] then return end
  File.open(file, 'w') {|f| f.write(newdata.join("\n")+"\n") }
end

config = parse_args()

pp config


if config[:stock]
  #patches we apply just to get the stock kernel to build with modern build tools
  puts "Patching linux-#{config[:majver]}.#{config[:minver]}.#{config[:subver]} for building.";
  patch_kernel(config,"patches/stock_patches")
  exit
end

if not config[:assume_yes]
  puts "Patching AXFS into linux-#{config[:majver]}.#{config[:minver]}.#{config[:subver]}.";
  puts "Using method: #{config[:insert_type]}";
  print "Proceed? [Y/n]: ";
  resp = STDIN.gets

  if resp =~ /[n|N]/
    puts "Goodbye!"
    exit
  end
end

#patches to kernel outside of axfs code
patch_kernel(config,"patches")

if config[:insert_type] == "none" then exit end
insert_line(config,"fs/Makefile", ["CONFIG_SQUASHFS","CONFIG_CRAMFS"], "obj-\$(CONFIG_AXFS)		+= axfs/");
insert_line(config,"fs/Kconfig",["fs/squashfs","fs/cramfs","config ECRYPT_FS"],"source \"fs/axfs/Kconfig\"");
insert_files(config,"fs/axfs");
insert_files(config,"include/linux");

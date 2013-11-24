#!/usr/bin/ruby
require 'optparse'

class LinuxVersionCleaner
  
  def initialize
    @output_file = ""
    @input_file = ""
    @kernel_version = ""
    @defs = Array.new
    @undefs = Array.new
    @option = OptionParser.new
    @script_name = File.basename($0)
    @option.set_summary_indent(' ')
    @option.banner = "\nUsage: #{@script_name} [options]\n"
    @option.define_head  "Cleans \"#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,21)\"\n"
    @option.on("-o", "--output_file=value", String, "Path to the output file") { |o| @output_file = o } 
    @option.on("-i", "--input_file=value", String, "Path to the input file") { |i| @input_file = i }
    @option.on("-k", "--kernel_version=value", String, "Current kernel version (ex. 2.6.21)") { |k| @kernel_version = k }
    @option.on("-d", "--def=value", String, "example: -d FOO=2,BAR") { |d| @defs = d.split(",") }
    @option.on("-u", "--undef=value", String, "example: -u FOO,BAR") { |u| @undefs = u.split(",") }
    @option.separator ""
    @option.on_tail("-h", "--help", "Show this help message.") { print @option; exit}
    
    @file = Array.new
  end
  
  def run(args)
    begin
      @option.parse!
    rescue OptionParser::ParseError => o
      print o
      print "\n"
      print @option
      exit
    end
    if (@input_file == "" or @output_file == "")
      print @option
      exit
    end

    if @kernel_version == ""
      @kernel_version = "1.1.1"
    end

    h,m,l = @kernel_version.split(".")
    @current_version = kernel_version(h,m,l)

    scan
    @process = unifdef
    @file.each { |line| @process.write(line) }
    @process.close_write
    write     
  end

  def scan
    file = File.new(@input_file,"r")
    file.each_line do |line|
      @file.push(replace(line))
    end
    file.close
  end
  
  def write
    file = File.new(@output_file,"w")
    @process.readlines.each { |line| file.write(line) }
    file.close
  end
  
  def kernel_version(h,m,l)
    o = h.to_i * 1000 * 1000
    o += m.to_i * 1000
    o += l.to_i
    output = "K" + o.to_s
    defline = output + "=" + o.to_s
    if not @defs.include?(defline)
      @defs.push(defline)
    end
    return output
  end
  
  def replace(line)
    line.gsub!(/LINUX_VERSION_CODE/,@current_version)
    if line =~ /KERNEL_VERSION\((\d+)\,(\d+)\,(\d+)\)/
      this_version = kernel_version($1,$2,$3)
      r = "KERNEL_VERSION(" + $1.to_s + "," + $2.to_s + "," + $3.to_s + ")"
      line.gsub!(r,this_version)
    end
    return line
  end
  
  def unifdef
    c = "unifdef"
    @defs.each do |d|
      c += " -D" + d.to_s
    end
    @undefs.each do |u|
      c += " -U" + u.to_s
    end
    return IO.popen(c,"w+")
  end
    
end

lvc = LinuxVersionCleaner.new
lvc.run(ARGV)

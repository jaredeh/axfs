require "fileutils"

a = ARGV[0]

if (a == "link")
  FileUtils.mkdir_p("./tovtf")
  f = File.new("./tovtf/file1", "w+")
  f.puts("foo")
  f.close
  pwd = Dir.pwd
  Dir.chdir("./tovtf")
  FileUtils.ln_s("file1","link1")
  Dir.chdir(pwd)
elsif (a == "node")
  FileUtils.mkdir_p("./tovtf")
  `mknod ./tovtf/node1 c 5 7`
elsif (a == "file")
  FileUtils.mkdir_p("./tovtf")
  f = File.new("./tovtf/file1", "w+")
  f.puts("foo")
  f.close
elsif (a == "createdestroy")
  FileUtils.mkdir_p("./tovtf")  
elsif (a == "filethreepages")
  FileUtils.mkdir_p("./tovtf")
  f = File.new("./tovtf/file1", "w+")
  f.write("a"*4096)
  f.write("b"*4096)
  f.write("c"*2051)
  f.close
elsif (a == "clean")
  FileUtils.rm_rf("./tovtf")
end
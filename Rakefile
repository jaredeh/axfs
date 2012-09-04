rootdir = Dir.pwd
utfpath = File.join(rootdir,"tests","utf")
libpath = File.join(rootdir,"libs")
srcpath = File.join(rootdir,"src")

task :lib do
  should_rebuild = `cd #{libpath}; rake check_if_should_rebuild`
  if should_rebuild.length > 0
    sh "cd #{libpath}; rake clobber"
    sh "cd #{libpath}; rake configure"
    sh "cd #{libpath}; rake all"
  end
end

task :all do
  sh "make -C #{srcpath} all"
  mv File.join(srcpath,"mkfs.axfs"), File.join(rootdir,"mkfs.axfs")
end

task :tests => [:unit_compile_test, :unit_tests]

task :unit_compile_test, :unit do |t, args|
  args.with_defaults(:unit => nil)
  if args[:unit] == nil
    sh "cd #{utfpath}; rake unit_compile_test"
  else
    sh "cd #{utfpath}; rake unit_compile_test[" + args[:unit] + "]"
  end
end

task :unit_tests, :unit, :test do |t, args|
  args.with_defaults(:unit => nil)
  if args[:unit] == nil
    sh "cd #{utfpath}; rake unit_tests"
  else
    sh "cd #{utfpath}; rake unit_tests[" + args[:unit] + "]"
  end
end

task :clean do
  sh "make -C #{srcpath} clean"
  rm_rf File.join(rootdir,"mkfs.axfs")
  sh "cd #{utfpath}; rake clean"  
  rm_rf File.join(rootdir,"tovtf")
end

task :clobber do
  sh "make -C #{srcpath} clobber"
  rm_rf File.join(rootdir,"mkfs.axfs")
  sh "cd #{utfpath}; rake clobber"  
  sh "cd #{libpath}; rake clobber"
  rm_rf File.join(rootdir,"tovtf")
end

task :default => :all
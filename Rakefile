rootdir = Dir.pwd
utfpath = File.join(rootdir,"tests","utf")

task :configure do
  cd rootdir
  sh "make configure"
end

task :lib do
  cd rootdir
  sh "make lib"
end

task :all do
  cd rootdir
  sh "make all"
end

task :tests => [:unit_compile_test, :unit_tests]

task :unit_compile_test, :unit do |t, args|
  args.with_defaults(:unit => nil)
  cd utfpath
  if args[:unit] == nil
    sh "rake unit_compile_test"
  else
    sh "rake unit_compile_test[" + args[:unit] + "]"
  end
  cd rootdir
end

task :unit_tests, :unit, :test do |t, args|
  args.with_defaults(:unit => nil)
  cd utfpath
  if args[:unit] == nil
    sh "rake unit_tests"
  else
    sh "rake unit_tests[" + args[:unit] + "]"
  end
  cd rootdir
end

task :clean do
  sh "make clean"
  cd utfpath
  sh "rake clean"
  cd rootdir
  rm_rf "tovtf"
end

task :clobber do
  sh "make clobber"
  cd utfpath
  sh "rake clobber"
  cd rootdir
end

task :default => :all
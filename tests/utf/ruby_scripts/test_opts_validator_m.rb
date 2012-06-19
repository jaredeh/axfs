require "test/unit"
require "fileutils"
require "yaml"

class TestOptsValidator < Test::Unit::TestCase
  def run_getopts(arg_str)
    str = ""
    cmd = File.dirname(File.dirname(__FILE__))
    cmd = File.join(cmd,"c_files/opts_validator.m/Functions/Scriptme/test")
    IO.popen(cmd + " " + arg_str + " 2>&1") { |io| str += io.read }
    #puts  "<--" + str + "-->"
    #puts "fafafa--" + cmd + " " + arg_str + " 2>&1 --fafafa"
    a = YAML::load(str)
    #puts "--[" + a.to_s + "]--"
    return a
  end

  def make_files
    FileUtils.mkdir_p("./tovtf")
    FileUtils.mkdir_p("./tovtf/input")
    f = File.new("./tovtf/profile", "w+")
    f.puts("foo, ,,")
    f.close
    f = File.new("./tovtf/input/file1", "w+")
    f.puts("foo")
    f.close
  end


  def test_simple
    make_files()
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output")
    assert_equal(true, a["opts_validator"]["valid"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --secondary_output ./tovtf/output2")
    assert_equal(true, a["opts_validator"]["valid"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --secondary_output ./tovtf/output2 --profile ./tovtf/profile")
    assert_equal(true, a["opts_validator"]["valid"])
    FileUtils.rm_rf("./tovtf/")
  end

  def test_simplefails
    make_files()
    a = run_getopts("--input ./tovtf/input")
    assert_equal(false, a["opts_validator"]["valid"])
    a = run_getopts("--output ./tovtf/output")
    assert_equal(false, a["opts_validator"]["valid"])
    a = run_getopts("--secondary_output ./tovtf/output2")
    assert_equal(false, a["opts_validator"]["valid"])
    a = run_getopts("--profile ./tovtf/profile")
    assert_equal(false, a["opts_validator"]["valid"])
    FileUtils.rm_rf("./tovtf/")
  end

  def test_compression
    make_files()
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --compression foo")
    assert_equal(false, a["opts_validator"]["valid"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --compression gzip")
    assert_equal(true, a["opts_validator"]["valid"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --compression lzo")
    assert_equal(true, a["opts_validator"]["valid"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --compression xz")
    assert_equal(true, a["opts_validator"]["valid"])
    FileUtils.rm_rf("./tovtf/")
  end

  def test_profile
  end

  def test_special
  end

  def test_block_size
  end

  def test_xip_size
  end

end

=begin
 -i,--input == input directory
 -o,--output == binary output file, the XIP part
 -d,--secondary_output == second binary output 
 -b,--block_size == compression block size
 -x,--xip_size == xip size of image
 -c,--compression == compression library
 -p,--profile == list of XIP pages
 -s,--special == special modes of execution
=end

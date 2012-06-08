require "test/unit"
require "yaml"

class TestGetopts < Test::Unit::TestCase
  def run_getopts(arg_str)
    str = ""
    cmd = File.dirname(File.dirname(__FILE__))
    cmd = File.join(cmd,"c_files/getopts.m/Functions/Scriptme/test")
    IO.popen(cmd + " " + arg_str + " 2>&1") { |io| str += io.read }
    #puts  "<--" + str + "-->"
    #puts "fafafa--" + cmd + " " + arg_str + " 2>&1 --fafafa"
    a = YAML::load(str)
    if a["axfs_config"] == nil
      return str
    end
    return a["axfs_config"]
  end

  def do_str_test(short,long,sec,data)
    a = run_getopts("-" + short)
    assert(a.include?("option requires an argument -- " + short) || a.include?("option requires an argument -- '" + short) || a.include?("invalid option --"))
    a = run_getopts("-" + short + " " + data.to_s)
    #puts a
    assert_equal(data, a[long])
    a = run_getopts("--" + long + " " + data.to_s)
    assert_equal(data, a[long])
    a = run_getopts("-" + short + " " + data.to_s + " " + sec)
    assert_equal(data, a[long])
    a = run_getopts("--" + long + " " + data.to_s + " " + sec)
    assert_equal(data, a[long])
  end

  def do_num_test(short,long,sec)
    do_str_test(short,long,sec,1234)
    [0,1,32,5000000000,50000000000,50000000000,500000000000,5000000000000,50000000000000,500000000000000,5000000000000000].each do |i|
      a = run_getopts("--" + long + " " + i.to_s)
      assert_equal(i, a[long])
    end
  end

  def test_input
    do_str_test("o","output","-i /dev/fo3","daffs")
  end

  def test_output
    do_str_test("i","input","-o daffs","data")
  end

  def test_secondary_output
    do_str_test("d","secondary_output","-i /dev/fo3","bbbbb")
  end

  def test_compression
    do_str_test("c","compression","-i /dev/fo3","ccccc")
  end

  def test_profile
    do_str_test("p","profile","-i /dev/fo3","ddddd")
  end

  def test_special
    do_str_test("s","special","-i /dev/fo3","eeeee")
  end

  def test_block_size
    do_num_test("b","block_size","-i /dev/fo3")
  end

  def test_xip_size
    do_num_test("x","xip_size", "-i gotozoo")
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

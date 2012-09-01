require "test/unit"
require "fileutils"
require "yaml"

class TestOptsValidator < Test::Unit::TestCase
  def run_getopts(arg_str)
    str = ""
    cmd = File.dirname(File.dirname(__FILE__))
    cmd = File.join(cmd,"./test")
    IO.popen(cmd + " " + arg_str + " 2>&1") { |io| str += io.read }
    #puts  "<--" + str + "-->"
    #puts "fafafa--" + cmd + " " + arg_str + " 2>&1 --fafafa"
    a = YAML::load(str)
    #puts "--[" + a.to_s + "]--"
    if a == nil
      a = Hash.new
      a["opts_validator"] = Hash.new
      a["opts_validator"][valid] = false
    end
    return a
  end

  def make_files
    FileUtils.mkdir_p("./tovtf")
    FileUtils.mkdir_p("./tovtf/input")
    FileUtils.mkdir_p("./tovtf/input2")
    f = File.new("./tovtf/profile", "w+")
    f.puts("foo, ,,")
    f.close
    f = File.new("./tovtf/input/file1", "w+")
    f.puts("foo")
    f.close
    f = File.new("./tovtf/input2/file1", "w+")
    f.puts("foo")
    f.close
    f = File.new("./tovtf/output", "w+")
    f.puts("foo")
    f.close
    f = File.new("./tovtf/output2", "w+")
    f.puts("foo")
    f.close
  end

  def test_simple
    make_files()
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output")
    assert_equal(true, a["opts_validator"]["valid"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --secondary_output ./tovtf/output2")
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

  def test_badfiles
    make_files()
    a = run_getopts("--input ./tovtf/nothere --output ./tovtf/output")
    assert_equal(false, a["opts_validator"]["valid"])
    a = run_getopts("--input ./tovtf/nothere --output ./tovtf/output --secondary_output ./tovtf/output2")
    assert_equal(false, a["opts_validator"]["valid"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/nothere")
    assert_equal(true, a["opts_validator"]["valid"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/nothere --secondary_output ./tovtf/output2")
    assert_equal(true, a["opts_validator"]["valid"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --secondary_output ./tovtf/nothere")
    assert_equal(true, a["opts_validator"]["valid"])
    a = run_getopts("--input ./tovtf/profile --output ./tovtf/output")
    assert_equal(false, a["opts_validator"]["valid"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/input2")
    assert_equal(false, a["opts_validator"]["valid"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --secondary_output ./tovtf/input2")
    assert_equal(false, a["opts_validator"]["valid"])
    a = run_getopts("--input ./tovtf/profile --output ./tovtf/output --secondary_output ./tovtf/output2")
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
    make_files()
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --profile ./tovtf/notthere")
    assert_equal(false, a["opts_validator"]["valid"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --secondary_output ./tovtf/output2 --profile ./tovtf/notthere")
    assert_equal(false, a["opts_validator"]["valid"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --profile ./tovtf/profile")
    assert_equal(true, a["opts_validator"]["valid"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --secondary_output ./tovtf/output2 --profile ./tovtf/profile")
    assert_equal(true, a["opts_validator"]["valid"])
    FileUtils.rm_rf("./tovtf/")
  end

  def do_test_XXX_size(arg)
    make_files()
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --#{arg} 4096")
    assert_equal(true, a["opts_validator"]["valid"])
    assert_equal(4096, a["axfs_config"]["#{arg}"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --#{arg} 65536")
    assert_equal(true, a["opts_validator"]["valid"])
    assert_equal(65536, a["axfs_config"]["#{arg}"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --#{arg} 4K")
    assert_equal(true, a["opts_validator"]["valid"])
    assert_equal(4096, a["axfs_config"]["#{arg}"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --#{arg} 4k")
    assert_equal(true, a["opts_validator"]["valid"])
    assert_equal(4096, a["axfs_config"]["#{arg}"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --#{arg} 4KB")
    assert_equal(true, a["opts_validator"]["valid"])
    assert_equal(4096, a["axfs_config"]["#{arg}"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --#{arg} 4kb")
    assert_equal(true, a["opts_validator"]["valid"])
    assert_equal(4096, a["axfs_config"]["#{arg}"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --#{arg} 4kB")
    assert_equal(true, a["opts_validator"]["valid"])
    assert_equal(4096, a["axfs_config"]["#{arg}"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --#{arg} 4Kb")
    assert_equal(true, a["opts_validator"]["valid"])
    assert_equal(4096, a["axfs_config"]["#{arg}"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --#{arg} 1M")
    assert_equal(true, a["opts_validator"]["valid"])
    assert_equal(1048576, a["axfs_config"]["#{arg}"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --#{arg} 1m")
    assert_equal(true, a["opts_validator"]["valid"])
    assert_equal(1048576, a["axfs_config"]["#{arg}"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --#{arg} 1MB")
    assert_equal(true, a["opts_validator"]["valid"])
    assert_equal(1048576, a["axfs_config"]["#{arg}"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --#{arg} 1mb")
    assert_equal(true, a["opts_validator"]["valid"])
    assert_equal(1048576, a["axfs_config"]["#{arg}"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --#{arg} 1mB")
    assert_equal(true, a["opts_validator"]["valid"])
    assert_equal(1048576, a["axfs_config"]["#{arg}"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --#{arg} 1Mb")
    assert_equal(true, a["opts_validator"]["valid"])
    assert_equal(1048576, a["axfs_config"]["#{arg}"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --#{arg} 1G")
    assert_equal(true, a["opts_validator"]["valid"])
    assert_equal(1073741824, a["axfs_config"]["#{arg}"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --#{arg} 1g")
    assert_equal(true, a["opts_validator"]["valid"])
    assert_equal(1073741824, a["axfs_config"]["#{arg}"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --#{arg} 1GB")
    assert_equal(true, a["opts_validator"]["valid"])
    assert_equal(1073741824, a["axfs_config"]["#{arg}"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --#{arg} 1gb")
    assert_equal(true, a["opts_validator"]["valid"])
    assert_equal(1073741824, a["axfs_config"]["#{arg}"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --#{arg} 1gB")
    assert_equal(true, a["opts_validator"]["valid"])
    assert_equal(1073741824, a["axfs_config"]["#{arg}"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --#{arg} 1Gb")
    assert_equal(true, a["opts_validator"]["valid"])
    assert_equal(1073741824, a["axfs_config"]["#{arg}"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --#{arg} 1bB")
    assert_equal(false, a["opts_validator"]["valid"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --#{arg} 0x1000")
    assert_equal(true, a["opts_validator"]["valid"])
    assert_equal(4096, a["axfs_config"]["#{arg}"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --#{arg} 0X1000")
    assert_equal(true, a["opts_validator"]["valid"])
    assert_equal(4096, a["axfs_config"]["#{arg}"])
    a = run_getopts("--input ./tovtf/input --output ./tovtf/output --#{arg} 0xFFFFF")
    assert_equal(true, a["opts_validator"]["valid"])
    assert_equal(1048575, a["axfs_config"]["#{arg}"])
    FileUtils.rm_rf("./tovtf/")
  end

  def test_page_size
    do_test_XXX_size("page_size")
  end

  def test_block_size
    do_test_XXX_size("block_size")
  end

  def test_xip_size
    do_test_XXX_size("xip_size")
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

require "test/unit"
require "../../src/wrapper.rb"
#foo = gets
#puts foo

class TestCBlocks < Test::Unit::TestCase
  def set_acfg
    config = Hash.new
    config[:compression] = "lzo"
    config[:page_size] = 4096
    config[:block_size] = 64*1024
    config[:xip_size] = 64*1024*1024
    config[:max_nodes] = 1024
    acfg = CreateAxfsConfig(config)
    CBlocksInterface.CBlocks___set_acfg(acfg)
  end

  def make_node(str)
    p = Hash.new
    p[:data] = str
    page = CreatePageStruct(p)
    n = Hash.new
    n[:page] = page
    return CreateAxfsNode(n)
  end
 
  def test_one_small_node
    set_acfg
    cb = CBlocks.new
    node = make_node("a"*2000)
    cb.addNode(node)
    size = cb.size
    assert size <= 100
    assert_not_equal(0, size)
    cb.free
  end

  def test_one_big_node
    set_acfg
    cb = CBlocks.new
    node = make_node("a"*4096)
    length = cb.length
    cb.addNode(node)
    length = cb.length
    puts length
    size = cb.size
    puts size
    puts cb.data.read_string.hexdump
    assert size <= 100
    assert_not_equal(0, size)
    cb.free
  end

end

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
    acfg = CBlocks.CreateAxfsConfig(config)
    CBlocksInterface.CBlocks___set_acfg(acfg)
  end

  def make_node(cb,str)
    p = Hash.new
    p[:data] = str
    page = cb.CreatePageStruct(p)
    n = Hash.new
    n[:page] = page
    return cb.CreateAxfsNode(n)
  end
 
  def test_one_small_node
    set_acfg
    cb = CBlocks.new
    node = make_node(cb,"a"*2000)
    cb.addNode(node)
    length = cb.length
    size = cb.size
    assert size <= 100
    assert_not_equal(0, size)
    cb.free
  end

  def test_one_pagesize_node
    set_acfg
    cb = CBlocks.new
    node = make_node(cb,"a"*4096)
    cb.addNode(node)
    length = cb.length
    size = cb.size
    assert size <= 100
    assert_not_equal(0, size)
    cb.free
  end

  def test_five_small_node
    set_acfg
    cb = CBlocks.new
    cb.addNode(make_node(cb,"a"*2000))
    cb.addNode(make_node(cb,"b"*2000))
    cb.addNode(make_node(cb,"c"*2000))
    cb.addNode(make_node(cb,"d"*2000))
    cb.addNode(make_node(cb,"e"*2000))
    length = cb.length
    size = cb.size
    assert size <= 100
    assert_not_equal(0, size)
    cb.free
  end

  def test_five_pagesize_node
    set_acfg
    cb = CBlocks.new
    s = 4096
    ["a","b","c","d","e",].each do |d|
      cb.addNode(make_node(cb,d*s))
    end
    length = cb.length
    size = cb.size
    assert size <= 1000
    assert_not_equal(0, size)
    cb.free
  end

  def test_26_pagesize_node
    set_acfg
    cb = CBlocks.new
    s = 4096
    a = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]
    a.each do |d|
      cb.addNode(make_node(cb,d*s))
    end
    length = cb.length
    size = cb.size
    assert size <= 1000
    assert_not_equal(0, size)
    cb.free
  end

  def test_26_small_node
    set_acfg
    cb = CBlocks.new
    s = 200
    a = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]
    a.each do |d|
      cb.addNode(make_node(cb,d*s))
    end
    length = cb.length
    size = cb.size
    assert size <= 1000
    assert_not_equal(0, size)
    cb.free
  end

  def test_1024_pagesize_node
    set_acfg
    cb = CBlocks.new
    s = 4096
    1024.times do |d|
      cb.addNode(make_node(cb,d*s))
    end
    length = cb.length
    size = cb.size
    assert size <= 5000
    assert_not_equal(0, size)
    cb.free
  end

  def test_1024_small_node
    set_acfg
    cb = CBlocks.new
    s = 200
    1024.times do |d|
      cb.addNode(make_node(cb,d*s))
    end
    length = cb.length
    size = cb.size
    assert size <= 3000
    assert_not_equal(0, size)
    cb.free
  end

end
#    ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"].each do |d|

require 'rubygems'
require 'ffi'

class String
  def hexdump
    i = 1
    rr = ""
    while (self.length > 16*(i-1))
      a=self.slice(16*(i-1)..(16*i)-1)
      rr += sprintf("%06x: %4.4x %4.4x %4.4x %4.4x   %4.4x %4.4x %4.4x %4.4x ", (i-1)*16,  *a.unpack("n16"))
      rr += sprintf("|%s|\n", a.tr("^\040-\176","."))
      i += 1
    end
    return rr
  end
end


module CLib
  extend FFI::Library
  ffi_lib File.expand_path(File.join(File.dirname(__FILE__),'libtest.so'))
  attach_function :malloc, [ :size_t ], :pointer
end

module CBlocksInterface
  extend FFI::Library
  ffi_lib File.expand_path(File.join(File.dirname(__FILE__),'libtest.so'))
  attach_function :CBlocks___new, [], :pointer
  attach_function :CBlocks___addNode, [ :pointer, :pointer ], :void
  attach_function :CBlocks___data, [:pointer], :pointer
  attach_function :CBlocks___size, [:pointer], :uint64
  attach_function :CBlocks___length, [:pointer], :uint64
  attach_function :CBlocks___initialize, [:pointer], :void
  attach_function :CBlocks___free, [:pointer], :void
  attach_function :CBlocks___set_acfg, [:pointer], :void
end

class CBlocks

  attr_accessor :cb

  def initialize
    @cb = CBlocksInterface.CBlocks___new
    @nodes_anchor = Array.new
    @pages_anchor = Array.new
 end

  def addNode(node)
    return CBlocksInterface.CBlocks___addNode(@cb,node)    
  end

  def data
    return CBlocksInterface.CBlocks___data(@cb)    
  end

  def size
    return CBlocksInterface.CBlocks___size(@cb)    
  end

  def length
    return CBlocksInterface.CBlocks___length(@cb)    
  end

  def free
    return CBlocksInterface.CBlocks___free(@cb)    
  end

  def CreateAxfsNode(in_node)
    node_ptr = FFI::MemoryPointer.new :pointer
    node_ptr = CLib.malloc(1024)
    node = AxfsNode.new(node_ptr)
    node[:page] = in_node[:page].pointer
    node[:next] = in_node[:next] == nil ? 0 : in_node[:next]
    node[:cboffset] = in_node[:cboffset].to_i
    in_node = nil
    @nodes_anchor.push node
    return node
  end

  def CreatePageStruct(in_page)
    page_ptr = FFI::MemoryPointer.new :pointer
    page_ptr = CLib.malloc(16000)
    page = PageStruct.new(page_ptr)
    page[:data] = FFI::MemoryPointer.from_string(in_page[:data].to_s)
    page[:cdata] = FFI::MemoryPointer.from_string(in_page[:cdata].to_s)
    page[:length] = in_page[:data].to_s.length
    page[:clength] = in_page[:clength].to_i
    page[:rb_node] = in_page[:rb_node].to_i
  
    in_page = nil
    @pages_anchor.push page
    return page
  end

  def self.CreateAxfsConfig(config)
    acfg_ptr = FFI::MemoryPointer.new :pointer
    acfg_ptr = CLib.malloc(4096)
    acfg = AxfsConfig.new(acfg_ptr)

    acfg[:input] = FFI::MemoryPointer.from_string(config[:input].to_s + "\x0")
    acfg[:output] = FFI::MemoryPointer.from_string(config[:output].to_s + "\x0")
    acfg[:secondary_output] = FFI::MemoryPointer.from_string(config[:secondary_output].to_s + "\x0")
    acfg[:compression] = FFI::MemoryPointer.from_string(config[:compression].to_s + "\x0")
    acfg[:page_size_str] = FFI::MemoryPointer.from_string(config[:page_size_str].to_s + "\x0")
    acfg[:block_size_str] = FFI::MemoryPointer.from_string(config[:block_size_str].to_s + "\x0")
    acfg[:xip_size_str] = FFI::MemoryPointer.from_string(config[:xip_size_str].to_s + "\x0")
    acfg[:profile] = FFI::MemoryPointer.from_string(config[:profile].to_s + "\x0")
    acfg[:special] = FFI::MemoryPointer.from_string(config[:special].to_s + "\x0")
    acfg[:page_size] = config[:page_size].to_i
    acfg[:block_size] = config[:block_size].to_i
    acfg[:xip_size] = config[:xip_size].to_i
    acfg[:max_nodes] = config[:max_nodes].to_i

    return acfg
  end
end

class AxfsNode < FFI::Struct
  #struct axfs_node {
  #  struct page_struct *page;
  #  struct axfs_node *next;
  #  uint64_t cboffset;
  #};
  layout :page, :pointer,
    :next, :pointer,
    :cboffset, :uint64
end

class PageStruct < FFI::Struct
  #struct page_struct {
  #  void *data;
  #  uint64_t length;
  #  void *cdata;
  #  uint64_t clength;
  #  rb_red_blk_node rb_node;
  #};
  layout :data, :pointer,
    :length, :uint64,
    :cdata, :pointer,
    :clength, :uint64,
    :rb_node, :pointer
end

class AxfsConfig < FFI::Struct
  #struct axfs_config {
    #char *input;
    #char *output;
    #char *secondary_output;
    #char *compression;
    #uint64_t page_size;
    #char *page_size_str;
    #uint64_t block_size;
    #char *block_size_str;
    #uint64_t xip_size;
    #char *xip_size_str;
    #char *profile;
    #char *special;
    #uint64_t max_nodes;
  #};
  layout :input, :pointer,
    :output, :pointer,
    :secondary_output, :pointer,
    :compression, :pointer,
    :page_size, :uint64,
    :page_size_str, :pointer,
    :block_size, :uint64,
    :block_size_str, :pointer,
    :xip_size, :uint64,
    :xip_size_str, :pointer,
    :profile, :pointer,
    :special, :pointer,
    :mmap_size, :uint64,
    :max_nodes, :uint64,
    :max_text_size, :uint64,
    :max_number_files, :uint64,
    :max_filedata_size, :uint64,
    :real_number_files, :uint64,
    :real_number_nodes, :uint64,
    :real_imagesize, :uint64,
    :version_major, :uint8,
    :version_minor, :uint8,
    :version_sub, :uint8

end



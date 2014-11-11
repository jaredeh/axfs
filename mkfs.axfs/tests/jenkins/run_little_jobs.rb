require 'rubygems'
require 'jenkins_api_client'
require 'yaml'

@client = JenkinsApi::Client.new(YAML.load_file(File.expand_path("~/.jenkins_api_login.yaml")))

puts @client.job.list("")

unittests = ["MkfsUnitTest__astrings.m","MkfsUnitTest__image_builder.m","MkfsUnitTest__axfs_helper.m","MkfsUnitTest__inodes.m","MkfsUnitTest__ba_nodes.m","MkfsUnitTest__modes.m","MkfsUnitTest__bytetable.m","MkfsUnitTest__nodes.m","MkfsUnitTest__c_blocks.m","MkfsUnitTest__opts_validator.m","MkfsUnitTest__comp_nodes.m","MkfsUnitTest__pages.m","MkfsUnitTest__compressor.m","MkfsUnitTest__region.m","MkfsUnitTest__dir_walker.m","MkfsUnitTest__super.m","MkfsUnitTest__falloc.m","MkfsUnitTest__xip_nodes.m","MkfsUnitTest__getopts.m"]

unittests.each do |test|
  puts test
  @client.job.build(test)
end

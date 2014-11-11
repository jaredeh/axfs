require 'rubygems'
require 'jenkins_api_client'

@client = JenkinsApi::Client.new(:server_ip => ARGV[0], :server_port => '8080', :username => '', :password => '', :jenkins_path => "/jenkins-axfs", :debug => true)
puts @client.job.list_all
bd = File.expand_path(File.dirname(__FILE__) + '/jobs')
Dir.entries(bd).sort.each do |dir|
  if dir == "." or dir == ".." or dir == "MkfsBuildTest"
    next
  end
  oldjob = File.join(bd,dir)
  xmld = File.read(File.join(oldjob,"config.xml"))
  xml = ""
  xmld.each_line do |line|
    if line =~ /assignedNode/
      next
    end
    xml += line
  end
  @client.job.create(dir,xml)
end

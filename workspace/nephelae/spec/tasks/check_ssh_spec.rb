require 'rubygems'
require "rake"

describe "Test task that check ssh connection with a key" do
  before do
    @rake = Rake::Application.new
    Rake.application = @rake
    Rake.application.rake_require "lib/tasks/check_ssh"
    Rake::Task.define_task(:environment)
  end

  it "Should set ssh_key_connecting to false if connection fail" do
    zone = Factory(:zone)
    host1 = Host.create!(:name => "host1", :username => "root", :password => "password", :ip => "127.0.0.1", :zone => zone)
    host2 = Host.create!(:name => "host2", :username => "root", :password => "password", :ip => "0.0.0.0", :zone => zone)
    
    ssh_executor = SSHExecutor.new(nil, nil)
    SSHExecutor.stub!(:new).and_return(ssh_executor)
    
    ssh_executor.should_receive(:exec).with(:ssh_check).and_raise(Net::SSH::AuthenticationFailed)
    ssh_executor.should_receive(:exec).with(:ssh_check)
    
    @rake[:"nephelae:check_ssh"].invoke
    Host.find(host1).ssh_key_connecting.should be_false
    Host.find(host2).ssh_key_connecting.should be_true

  end
end


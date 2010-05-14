require File.dirname(__FILE__) + "/../spec_helper"

describe SSHExecutor do
  context "with key (no password)" do
    before :each do
      @message = "This is a test"
      @host = "localhost"
      @user = "root"
      @ssh_executor = SSHExecutor.new(@host, @user)
    end

    it "should build script .sh from base file" do
      response = SSHExecutor.render_script("#{SSHExecutor::scripts_folder}/test.sh.erb", {:param => @message})
      response.should include_text("#This is a comment")
      response.should include_text('x = "This is a test"') 
      response.should include_text("echo $x")
    end
  
    it "should execute generated script through ssh" do
      sh_code = "Correct command"
      response = {:out => "STDOUT", :status => 0}
    
      SSHExecutor.should_receive(:render_script).with("#{SSHExecutor::scripts_folder}/test.sh.erb", {:param => @message}).and_return(sh_code)
      @ssh_executor.should_receive(:exec_in_ssh).with(sh_code).and_return(response)
      @ssh_executor.exec(:test, {:param => @message}).should be(response)
    end

    it "should call SSH services with the right host, user and key" do
      key = "#{RAILS_ROOT}/config/keys/development.key"
      known_hosts = "#{RAILS_ROOT}/config/ssh/known_hosts"
      Net::SSH.should_receive(:start).with(@host, @user, {:keys => [key], :user_known_hosts_file=>[known_hosts]})
      @ssh_executor.exec(:test, {:param => @message})
    end
  end
  
  context "with password" do
    before :each do
      @message = "This is a test"
      @host = "localhost"
      @user = "root"
      @password = "password"
      @ssh_executor = SSHExecutor.new(@host, @user, @password)
    end
    
    it "should call SSH services with the right host, user and password" do
      known_hosts = "#{RAILS_ROOT}/config/ssh/known_hosts"
      Net::SSH.should_receive(:start).with(@host, @user, {:password => @password, :user_known_hosts_file=>[known_hosts]})
      @ssh_executor.exec(:test, {:param => @message})
    end
    
  end
  
end

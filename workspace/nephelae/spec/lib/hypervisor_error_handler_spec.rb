require File.dirname(__FILE__) + '/../spec_helper'

describe "Hypervisor Error Handler" do
  
  before(:each) do
    @zone = Factory.create(:zone)
  	@new_master = Factory.create(:host, :zone => @zone)
		@old_master = Factory.create(:master, :zone => @zone)
  	@connection = "hypervisor connection"
  	@error_handler = HypervisorErrorHandler.new(@zone, XenAPI::NotMasterError.new("HOST_IS_SLAVE: #{@new_master.ip}"))
  end
  
  context "when connecting to the real master" do
    it "should return the connection" do
      @error_handler.should_receive(:connect_to).with(@new_master).and_return(@connection)
      @error_handler.send(:connect_to_real_master_at, @new_master.ip).should be(@connection)
    end
    
    it "should warn if can't connect" do
      error = RuntimeError.new "Error connecting to real master"
      @error_handler.should_receive(:connect_to).with(@new_master).and_raise error
      @error_handler.should_receive(:send_critical_warning_for).with(error).and_raise error
      lambda{@error_handler.send(:connect_to_real_master_at, @new_master.ip)}.should raise_error(RuntimeError)
    end
  end
  
  context "when making a slave become master" do
    it "should connect to it and return the connection" do
      @error_handler.should_receive(:change_to_master_on_hypervisor).with(@new_master)
      @error_handler.should_receive(:connect_to).with(@new_master).and_return(@connection)
      @error_handler.send(:make_it_master_and_connect, @new_master).should be(@connection)
    end
  
    it "should warn if can't make it master" do
      error = RuntimeError.new "Error changing slave to master on hypervisor"
      @error_handler.should_receive(:change_to_master_on_hypervisor).and_raise error
      @error_handler.should_receive(:send_critical_warning_for).with(error).and_raise error
      lambda{@error_handler.send(:make_it_master_and_connect, @new_master)}.should raise_error(RuntimeError)
    end
  end
  
  it "should be able change master on database" do
  	@error_handler.send(:change_to_master_on_db, @new_master)
  	@new_master.reload
  	@new_master.master.should be_true
  	@old_master.reload
  	@old_master.master.should be_false
  end
  
  context "when reconnecting to master" do
    it "should return the connection if no error happens" do
      @error_handler.should_receive(:connect_to).with(@old_master).and_return(@connection)
      @error_handler.send(:reconnect_to_master).should be(@connection)
    end
    
    it "should try a slave if reconnect fails" do
      error = XenAPI::ExpirationError.new("end of file")
      error_handler = HypervisorErrorHandler.new(@zone, error)
    
      error_handler.should_receive(:connect_to).with(@old_master).and_raise XenAPI::TimeoutError.new
      error_handler.should_receive(:check_first_slave_and_connect).and_return(@connection)
      error_handler.handle_error.should be(@connection)
    end
  end
  
  context "when changing master on hypervisor" do
    it "shouldn't raise exception if shell script status is 0" do
      ssh = SSHExecutor.new(@new_master.ip, @new_master.username)
      SSHExecutor.should_receive(:new).with(@new_master.ip, @new_master.username).and_return(ssh)
      ssh.should_receive(:exec).with(:xenserver_master_ha).and_return({:status => 0})

      @error_handler.send(:change_to_master_on_hypervisor, @new_master)
    end

    it "should raise exception if unsuccessful" do
      ssh = SSHExecutor.new(@new_master.ip, @new_master.username)
      SSHExecutor.should_receive(:new).with(@new_master.ip, @new_master.username).and_return(ssh)
      ssh.should_receive(:exec).with(:xenserver_master_ha).and_return({:status => 1, :out => "wrong command"})

      lambda{
              @error_handler.send(:change_to_master_on_hypervisor, @new_master)
            }.should raise_error("Could not change slave #{@new_master.ip} to master: (error number 1) wrong command")
    end
  end
  
  context "when an error happens on master" do
  
    it "should send mail and raise error if received an authentication error for the current master" do
      error = XenAPI::AuthenticationError.new("Authentication")
      error_handler = HypervisorErrorHandler.new(@zone, error)
      Mailer.should_receive(:deliver_error_email).with(@zone, error)
      
      lambda{
              error_handler.handle_error
            }.should raise_error(XenAPI::AuthenticationError)
    end
    
    it "should connect to real master if a NotMaster Error happens on master" do
      error = XenAPI::NotMasterError.new("HOST_IS_SLAVE: 192.168.200.200")
      error_handler = HypervisorErrorHandler.new(@zone, error)
      error_handler.should_receive(:connect_to_real_master_at).with("192.168.200.200").and_return(@connection)
  
      error_handler.handle_error.should be(@connection)
    end
    
    context "if a Expiration Error happens on master" do
      it "should reconnect" do
        error = XenAPI::ExpirationError.new("end of file")
        error_handler = HypervisorErrorHandler.new(@zone, error)
        error_handler.should_receive(:reconnect_to_master).and_return(@connection)
        error_handler.handle_error.should be(@connection)
      end
    end
    
    it "should check first slave and connect to it if received a Connection Error for the current master" do
      error = XenAPI::ConnectionError.new("no route to host")
      error_handler = HypervisorErrorHandler.new(@zone, error)
      error_handler.should_receive(:check_first_slave_and_connect).and_return(@connection)
      error_handler.handle_error.should be(@connection)
    end
    
    context "if a Connection Error happens on master" do
    
      it "should change slave to master on db if connection to it is successful" do
        error = XenAPI::ConnectionError.new("no route to host")
        SessionFactory.should_receive(:create)
        HypervisorConnection.should_receive(:hypervisor_session!).with(@new_master).and_return(@connection)
      
        error_handler = HypervisorErrorHandler.new(@zone, error)
        error_handler.send(:check_first_slave_and_connect).should be(@connection)
        @new_master.reload.master.should be_true
      
      end
      
      it "should raise error if connection to slave raises an error that is not authentication or not master error" do
        error = XenAPI::ConnectionError.new("no route to host")
        SessionFactory.should_receive(:create).and_raise("no route to host")
      
        error_handler = HypervisorErrorHandler.new(@zone, error)
        lambda{
                error_handler.send(:check_first_slave_and_connect)
              }.should raise_error("no route to host")
      end
      
      
      it "should send mail and raise error if connection to slave gives authentication error" do
        error = XenAPI::ConnectionError.new("no route to host")
        slave_error = XenAPI::AuthenticationError.new("wrong pass")
        
        error_handler = HypervisorErrorHandler.new(@zone, error)
        error_handler.should_receive(:connect_to).with(@new_master).and_raise(slave_error)
        
        Mailer.should_receive(:deliver_error_email).with(@zone, slave_error)

        lambda{
                error_handler.send(:check_first_slave_and_connect)
              }.should raise_error(XenAPI::AuthenticationError)
      end
      
      it "should turn slave into master on db and hypervisor and connect to it if connection to slave times out" do
        error = XenAPI::ConnectionError.new("no route to host")
        SessionFactory.should_receive(:create).and_raise(XenAPI::TimeoutError.new)
      
        error_handler = HypervisorErrorHandler.new(@zone, error)
        error_handler.should_receive(:make_it_master_and_connect).and_return(@connection)
        error_handler.send(:check_first_slave_and_connect).should be(@connection)
      end
      
      it "should connect to real master if slave gives a not master error" do
        error = XenAPI::ConnectionError.new("no route to host")
        SessionFactory.should_receive(:create).and_raise(XenAPI::NotMasterError.new("HOST_IS_SLAVE: 192.168.200.200"))
      
        error_handler = HypervisorErrorHandler.new(@zone, error)
        error_handler.should_receive(:connect_to_real_master_at).with("192.168.200.200").and_return(@connection)
        error_handler.send(:check_first_slave_and_connect).should be(@connection)
      end
      
    end
    
    it "should raise error if received a generic xenapi error for the current master" do
      generic_error = RuntimeError.new("LEROLERO")
      error_handler = HypervisorErrorHandler.new(@zone, generic_error)
      lambda{
              error_handler.handle_error
            }.should raise_error("LEROLERO")
    end
    
  end
  
end

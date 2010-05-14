require File.dirname(__FILE__) + '/../spec_helper'

describe Host do
  should_belong_to :zone
  
  context "when validating data" do
    before :each do
      # Needed to run validate_uniqueness of
      Factory(:host)
    end
    should_validate_presence_of :ip, :name, :username, :password, :zone
    should_validate_uniqueness_of :ip
  end

  it "should not be master by default" do
    subject.should_not be_master
    host = Factory(:host)
    Host.find(host.id).should_not be_master
  end
  
  it "should support master hosts" do
    subject.master = true
    subject.should be_master
  end
  
  context "- firewall" do
    subject { Factory(:host) }

    before(:each) do
      hypervisor_session = mock_session
      HypervisorConnection.stub!(:hypervisor_session).and_return(hypervisor_session)
      @vm = VirtualMachine.new
      @ssh = mock("SSHExecutor")
      SSHExecutor.should_receive(:new).with(subject.ip, subject.username).and_return(@ssh)
    end
  
    it "should insert ebtables rule for vm" do
      result = {:status => 0}
      @ssh.should_receive(:exec).with(:insert_ebtables_rule, {:vm => @vm}).and_return result
      subject.insert_ebtables_rule_for @vm
    end
    
    it "should raise error on insert ebtables rule if exit-status is not 0" do
      result = {:status => 1, :out => "Error"}
      @ssh.should_receive(:exec).with(:insert_ebtables_rule, {:vm => @vm}).and_return result
      lambda{subject.insert_ebtables_rule_for(@vm)}.should raise_error("Error inserting ebtables rule: #{result[:out]}")
    end
    
    it "should remove ebtables rule for vm" do
      result = {:status => 0}
      @ssh.should_receive(:exec).with(:remove_ebtables_rule, {:vm => @vm}).and_return result
      subject.remove_ebtables_rule_for @vm
    end
    
    it "should raise error on remove ebtables rule if exit-status is not 0" do
      result = {:status => 1, :out => "Error"}
      @ssh.should_receive(:exec).with(:remove_ebtables_rule, {:vm => @vm}).and_return result
      lambda{subject.remove_ebtables_rule_for(@vm)}.should raise_error("Error removing ebtables rule: #{result[:out]}")
    end
    
  end
end

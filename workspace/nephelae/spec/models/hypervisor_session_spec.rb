require File.dirname(__FILE__) + '/../spec_helper'

describe "hypervisor session creation" do
  
  it "should provide the hypervisor_session method to all ActiveRecords" do
    vm = VirtualMachine.new
    vm.should respond_to(:hypervisor_session)
  end
  
  it "should provide the hypervisor_session holded by ActiveRecord::Base class" do
    HypervisorConnection.should_receive(:hypervisor_session).and_return(:lalala)
    zone = Zone.new
    vm = VirtualMachine.new(:zone => zone)
    vm.hypervisor_session.should be(:lalala)
  end

  it "should register a global action that closes hypervisor sessions after each process execution" do
    ProcessSpecification.after_process_actions.should have_at_least(1).action
  end
  
  it "should re-do the last unsuccessful operation on the hypervisor after a successful connection"
    
end

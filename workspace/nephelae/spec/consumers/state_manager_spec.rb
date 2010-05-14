require File.dirname(__FILE__) + '/../spec_helper'

describe StateManager do
  before :each do
    @vm = Factory(:installed_vm)
    VirtualMachine.stub!(:find).and_return(@vm)
  end
  
  it "should power off the virtual machine" do
    processed_message_body = {:virtual_machine_id => @vm.id, :action => "shutdown"}
    
    @vm.should_receive(:power_off)
    subject.send(:handle, processed_message_body)
  end
  
  it "should force the virtual machine power off" do
    processed_message_body = {:virtual_machine_id => @vm.id, :action => "force_shutdown"}
    
    @vm.should_receive(:force_power_off)
    subject.send(:handle, processed_message_body)
  end
  
  it "should reboot the virtual machine" do
    processed_message_body = {:virtual_machine_id => @vm.id, :action => "restart"}
    
    @vm.should_receive(:reboot)
    subject.send(:handle, processed_message_body)
  end
  
  it "should force the virtual machine power off" do
    processed_message_body = {:virtual_machine_id => @vm.id, :action => "force_restart"}
    
    @vm.should_receive(:force_reboot)
    subject.send(:handle, processed_message_body)
  end
  
  it "should power on the virtual machine" do
    processed_message_body = {:virtual_machine_id => @vm.id, :action => "start"}
    
    @vm.should_receive(:power_on)
    subject.send(:handle, processed_message_body)
  end

  it "should uninstall the virtual machine" do
    processed_message_body = {:virtual_machine_id => @vm.id, :action => "uninstall"}
    
    @vm.should_receive(:uninstall)
    subject.send(:handle, processed_message_body)
  end

  it 'should log an error when receiving an invalid queue message' do
    processed_message_body = {:virtual_machine_id => @vm.id, :action => "invalid_action"}
    
    @vm.should_receive(:log_activity).with(:debug, anything)
    @vm.should_receive(:log_activity).with(:error, "Unknown action for changing virtual machine state: invalid_action")
    subject.send(:handle, processed_message_body)
  end
  
end

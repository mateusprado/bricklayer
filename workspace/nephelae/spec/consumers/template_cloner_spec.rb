require File.dirname(__FILE__) + '/../spec_helper'

describe TemplateCloner do
  before(:each) do
    @zone = Factory(:zone)
  end

  it "should be an exclusive consumer" do
    subject.class.exclusive?.should be_true
  end
  
  it "should select template and create machine based on queue message" do
    vm = Factory(:new_vm, :zone => @zone)
    processed_message_body = {:virtual_machine_id => vm.id}
    VirtualMachine.should_receive(:find).with(vm.id).and_return(vm)
    vm.should_receive(:clone_from_template).ordered
    vm.should_receive(:queue_installation).ordered

    subject.send(:handle, processed_message_body)
  end
end

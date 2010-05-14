require File.dirname(__FILE__) + '/../spec_helper'

describe InstallationSetup do
  before(:each) do
    @zone = Factory(:zone)
  end

  it "should be an exclusive consumer" do
    subject.class.exclusive?.should be_true
  end

  it "should change the current step to invalid_setup if an error happens" do
    VirtualMachine.without_callbacks do
      vm = Factory(:awaiting_validation_vm, :zone => @zone)

      VirtualMachine.stub!(:find).and_return(vm)
      vm.should_receive(:setup_installation).and_raise "Installation setup error"
      processed_message_body = {:virtual_machine_id => vm.id}
      subject.send(:handle, processed_message_body)

      vm.reload
      vm.status.should be(:invalid_setup)
    end
  end

  it "should request template clone" do
    vm = Factory(:awaiting_validation_vm, :zone => @zone)
    VirtualMachine.stub!(:find).and_return(vm)
    processed_message_body = {:virtual_machine_id => vm.id}

    vm.should_receive(:setup_installation).ordered
    vm.should_receive(:queue_template_clone).ordered

    subject.send(:handle, processed_message_body)
  end
end

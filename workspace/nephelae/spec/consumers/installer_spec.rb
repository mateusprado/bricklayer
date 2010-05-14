require File.dirname(__FILE__) + '/../spec_helper'

describe Installer do
  it "should be assigned to installer queue" do
    subject.queue_name.should =~ /Installer$/
  end

  it "should not be an exclusive consumer" do
    subject.class.exclusive?.should be_false
  end

  context "when processing callback" do
    before :each do
      @vm = Factory(:new_vm)
      @processed_message_body = {:virtual_machine_id => @vm.id}
      VirtualMachine.should_receive(:find).with(@vm.id).and_return @vm
    end

    it "it should call install if the vm current step is :machine_created" do
      @vm.change_status(:machine_created)
      lambda{ subject.send(:handle, @processed_message_body) }.should_not raise_error(InvalidInitialState)
    end

    it "it should raise an error when trying to call install if the vm status is different from :machine_created" do
      @vm.change_status(:installed)
      lambda{ subject.send(:handle, @processed_message_body) }.should raise_error(InvalidInitialState)
    end
  end

  it "should raise an error if receiving an invalid machine id" do
    processed_message_body = {:virtual_machine_id => 123}
    VirtualMachine.should_receive(:find).with(123).and_return nil
    lambda{subject.send(:handle, processed_message_body)}.should raise_error
  end
end

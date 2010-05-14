require File.dirname(__FILE__) + '/../spec_helper'

describe SetupInstallationSteps do

  before(:each) do
    @zone = Factory(:zone)
    account = Factory(:test_account)
    VirtualMachine.without_callbacks do
      @vm = Factory(:awaiting_validation_vm, :zone => @zone, :account => account)
    end
  end

  it "should get name and IP, select template, create machine and notify peers when installing" do
    @vm.should_receive(:validate_zone_availability).ordered
    @vm.should_receive(:select_name).ordered
    @vm.should_receive(:select_public_ip).ordered
    @vm.should_receive(:select_private_ip).ordered
    @vm.setup_installation
    @vm.status.should be(:not_created)
  end

  it "should select a name for the virtual machine" do
    @vm.select_name
    @vm.name.should be("CLOUD_#{@vm.id}")
  end

  it "should set the vm's public ip" do
    expected_public_ip = Ip.new
    Ip.should_receive(:find_free_public_ip).and_return(expected_public_ip)
    lambda{@vm.select_public_ip}.should_not raise_error
    @vm.public_ip.should be(expected_public_ip)
  end

  it "should raise error if can't select public ip" do
    Ip.should_receive(:find_free_public_ip).and_return nil
    lambda{@vm.select_public_ip}.should raise_error
  end

  it "should raise error if can't select vlan" do
    Vlan.should_receive(:find_for).and_return nil
    lambda{@vm.select_private_ip}.should raise_error
  end

  it "should set the vm's private ip" do
    Vlan.without_callbacks do
      @vlan = Factory(:vlan)
    end
    Vlan.should_receive(:find_for).with(@vm).and_return @vlan
    expected_private_ip = Ip.new
    Ip.should_receive(:find_free_private_ip).with(@vlan).and_return(expected_private_ip)
    lambda{@vm.select_private_ip}.should_not raise_error
    @vm.private_ip.should be(expected_private_ip)
  end

  it "should raise error if can't select private ip" do
    Vlan.without_callbacks do
      @vlan = Factory(:vlan)
    end
    Vlan.should_receive(:find_for).and_return @vlan
    Ip.should_receive(:find_free_private_ip).with(@vlan).and_return nil
    lambda{@vm.select_private_ip}.should raise_error
  end

  context 'when validating the zone availability' do
    it 'should raise an error if the zone cannot accomodate the machine' do
      @vm.zone.should_receive(:can_accomodate_machine?).and_return false
      lambda{@vm.validate_zone_availability}.should raise_error
    end

    it 'should not raise an error if the zone can accomodate the machine' do
      @vm.zone.should_receive(:can_accomodate_machine?).and_return true
      lambda{@vm.validate_zone_availability}.should_not raise_error
    end
  end

end

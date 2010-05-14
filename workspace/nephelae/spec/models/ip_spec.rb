require 'spec_helper'

describe Ip do

  should_belong_to :ip_range
  should_have_one :virtual_machine, :foreign_key => :private_ip_id

  should_validate_presence_of :address, :ip_range
  should_allow_values_for :address, '10.1.2.9', '0.0.0.0', '255.255.255.255'
  should_not_allow_values_for :address, '1.2.9', '-1.0.0.0', '255.255.255.256'

  context "(class methods)" do
    it "should find a free private ip on the given vlan" do
      vlan = Factory(:vlan)

      VirtualMachine.without_callbacks(:validate_account_limits) do
        vm = Factory(:installed_vm)

        vlan.ip_range.send(:create_ips)
        used_ip = vlan.ip_range.ips[0]

        vm.private_ip = used_ip
        vm.save
      end

      free_ip = vlan.ip_range.reload.ips[1]
      Ip.find_free_private_ip(vlan).should be(free_ip)
    end

    it "should find a free public ip" do
      vm = Factory(:installed_vm)
      ip_range = Factory(:ip_range)

      VirtualMachine.without_callbacks(:validate_account_limits) do
        ip_range.send(:create_ips)
        ip_range.ips.reload
        used_ip = ip_range.ips[0]

        vm.public_ip = used_ip
        vm.save
      end

      free_ip = ip_range.ips[1]
      Ip.find_free_public_ip.should be(free_ip)
    end
  end

  it "should return the mask associated with the ip's ip_range" do
    subject.ip_range = Factory.build(:ip_range, :mask => 99)
    subject.mask.should == 99
  end
end

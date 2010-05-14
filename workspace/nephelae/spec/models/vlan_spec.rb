require File.dirname(__FILE__) + '/../spec_helper'

describe Vlan do

  should_validate_presence_of :number, :zone
  should_validate_numericality_of :number, :greater_than_or_equal_to => Vlan::MINIMUM, :less_than_or_equal_to => Vlan::MAXIMUM

  should_belong_to :zone
  should_have_many :virtual_machines
  should_have_one  :ip_range, :autosave => true, :dependent => :destroy
  should_have_many :ips, :through => :ip_range

  context 'when validating a new instance' do
    it "should create the ip_range after saving the record" do
      subject.number = 1101
      subject.zone = Factory(:zone)
      subject.save

      subject.ip_range.address.should be("10.1.0.0")
    end
    
    it "should generate network 10.x.112.96/27 for VLAN 2000" do
      subject.number = 2000
      subject.zone = Factory(:zone)
      subject.save

      subject.ip_range.address.should be("10.1.112.96")
      subject.ip_range.mask.should be(27)
    end
    
  end

  context "when selecting vlan for vm" do
    before :all do
      # Supressing :create_range to speed up the tests
      Vlan.without_callbacks(:create_range) do
        @zone = Factory(:zone)
        @zone.generate_vlans(Vlan::MINIMUM..(Vlan::MINIMUM+2))
        @zone.reload
      end
      @system_image = Factory(:centos)
      @account = Factory(:test_account)
      VirtualMachine.without_callbacks do
        @vm = Factory(:new_vm, :zone => @zone, :account => @account, :system_image => @system_image, :password => '^P4ssw0rd$')
      end
    end

    after :all do
      @vm.destroy
      @zone.destroy
      @account.destroy
      @system_image.destroy
    end

    it "should select the first free vlan on a new zone" do
      used_vlan = @zone.vlans[0]
      other_account_vm = Factory(:new_vm, :zone => @zone, :account => Factory(:client_account), :vlan => used_vlan, :password => '^P4ssw0rd$')
      vlan = Vlan.find_for(@vm)
      vlan.should be @zone.vlans[1]
    end

    it "should select the same vlan on a used zone" do
      used_vlan = @zone.vlans[0]
      same_account_vm = Factory(:new_vm, :zone => @zone, :account => @account, :vlan => used_vlan, :password => '^P4ssw0rd$')
      vlan = Vlan.find_for(@vm)
      vlan.should be used_vlan
    end

    it "should return nil if all vlans are in use on a new zone" do
      @zone.vlans.each do |used_vlan|
        Factory(:new_vm, :zone => @zone, :account => Account.create!(:login => "login#{used_vlan.number}"), :vlan => used_vlan, :password => '^P4ssw0rd$')
      end
      vlan = Vlan.find_for(@vm)
      vlan.should be_nil
    end

    it "should return nil if vlan is full on the used zone"
  end
end

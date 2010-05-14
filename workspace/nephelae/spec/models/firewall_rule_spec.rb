require 'spec_helper'
require 'set'

describe FirewallRule do
  should_belong_to :virtual_machine
  should_validate_presence_of :virtual_machine, :description

  before :all do
    @zone = Factory(:zone)
    firewall = Factory(:firewall, :zone => @zone)
    @account = Factory(:test_account)
    @public_ip_range = Factory(:ip_range, :address => '123.123.123.0')
    @private_ip_range = Factory(:ip_range, :address => '10.0.0.0')
    @vm = Factory(:installed_vm,
                  :zone       => @zone,
                  :account    => @account,
                  :public_ip  => @public_ip_range.ips.first,
                  :private_ip => @private_ip_range.ips.first
                 )
  end

  after :all do
    @private_ip_range.destroy
    @public_ip_range.destroy
    @zone.destroy
    @account.destroy
  end
  
  it "should be pending" do
    subject.should be_pending
  end
  
  it "should not be pending" do
    subject.status = :done
    subject.should_not be_pending
  end

  it 'should return firewall rules for given virtual_machine' do
    rules = Set.new
    FirewallRule.without_callbacks do
      rules << Factory(:nat_firewall_rule, :virtual_machine => @vm)
      rules << Factory(:filter_firewall_rule, :virtual_machine => @vm)
    end

    Set.new(FirewallRule.find_all_by_virtual_machine_id(@vm)).should == rules
  end

  it "should return as internal address the VM's private IP" do
    subject.virtual_machine = @vm
    subject.internal_address.should == @vm.private_ip.address
    subject.internal_address.should_not be_nil
  end

  it "should return as firewall the VM's firewall" do
    subject.virtual_machine = @vm
    subject.firewall.should == @vm.firewall
    subject.firewall.should_not be_nil
  end

  it "should queue the firewall rule's removal" do
    rule = Factory(:filter_firewall_rule, :virtual_machine => @vm, :status => :done)
    FirewallManager.should_receive(:publish).with(:firewall_rule_id => rule.id, :action => "remove")
    rule.queue_removal
    rule.status.should == :removing
  end
end

require 'spec_helper'

describe NatFirewallRule do
  before :all do
    @zone = Factory(:zone)
    @firewall_ip_address = '10.11.0.1'
    firewall = Factory(:firewall, :zone => @zone, :ip_address => @firewall_ip_address)
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

  subject { NatFirewallRule.new :virtual_machine => @vm }
  
  it "should have a default description" do
    subject.description.should be("Default Nat Rules for machine: #{@vm.uuid}")
  end

  it "should return as external address the VM's public_ip" do
    subject.external_address.should be(@vm.public_ip.address)
  end

  it "should return as external mask the VM's public_ip.ip_range.mask" do
    subject.external_mask.should_not be_nil
    subject.external_mask.should be(@vm.public_ip.ip_range.mask)
  end

  it 'should execute the insert_nat_rules script via SSH on the firewall' do
    FirewallRule.without_callbacks do
      subject.status = :inserting
      mocked_ssh = mock(:ssh)
      mocked_ssh.should_receive(:exec).with(:insert_nat_rules, {:rule => subject}).and_return({:status => 0})
      SSHExecutor.stub!(:new).with(@firewall_ip_address, 'sservice').and_return(mocked_ssh)
      subject.insert
      subject.status.should == :done
    end
  end

  it 'should execute the remove_nat_rules script via SSH on the firewall' do
    FirewallRule.without_callbacks do
      subject.status = :removing
      mocked_ssh = mock(:ssh)
      mocked_ssh.should_receive(:exec).with(:remove_nat_rules, {:rule => subject}).and_return({:status => 0})
      SSHExecutor.stub!(:new).with(@firewall_ip_address, 'sservice').and_return(mocked_ssh)
      subject.remove
      subject.status.should == :done
    end
  end

  context 'when trying to access filter properties' do
    it 'should raise and error when accessing filter_address' do
      lambda { subject.filter_address }.should raise_error
    end

    it 'should raise and error when accessing filter_port' do
      lambda { subject.filter_port }.should raise_error
    end

    it 'should raise and error when accessing filter_protocol' do
      lambda { subject.filter_protocol }.should raise_error
    end
  end

  context 'when creating or destroying a rule' do
    before :each do
      @ssh = mock('ssh')
      SSHExecutor.stub!(:new).and_return(@ssh)
      @result = {:status => 0, :out => ''}
    end

    it "should insert a nat rule in the gateway when created" do
      subject.should_receive(:queue_insertion)
      subject.save
    end

    it "should queue a nat rule removal when destroyed" do
      subject.should_receive(:queue_removal)
      subject.destroy
    end
  end
end

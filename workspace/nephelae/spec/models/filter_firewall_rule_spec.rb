require 'spec_helper'

describe FilterFirewallRule do
  should_validate_presence_of :filter_address, :filter_port, :filter_protocol
  should_validate_numericality_of :filter_port, :only_integer => true, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 65000

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

  subject { Factory.build(:filter_firewall_rule, :virtual_machine => @vm) }
  
  it "should have a default source address and description" do
    rule = FilterFirewallRule.new(:virtual_machine => @vm, :filter_port => 22, :filter_protocol => :tcp)
    rule.filter_address.should be("0.0.0.0/0")
    rule.description.should be("Firewall rule source: 0.0.0.0/0, protocol: tcp, port: 22")
  end

  it 'should execute the insert_filter_rules script via SSH on the firewall' do
    FirewallRule.without_callbacks do
      subject.status = :inserting
      mocked_ssh = mock(:ssh)
      mocked_ssh.should_receive(:exec).with(:insert_filter_rules, {:rule => subject}).and_return({:status => 0})
      SSHExecutor.stub!(:new).with(@firewall_ip_address, 'sservice').and_return(mocked_ssh)
      subject.insert
      subject.status.should == :done
    end
  end

  it 'should execute the remove_filter_rules script via SSH on the firewall' do
    FirewallRule.without_callbacks do
      subject.status = :removing
      mocked_ssh = mock(:ssh)
      mocked_ssh.should_receive(:exec).with(:remove_filter_rules, {:rule => subject}).and_return({:status => 0})
      SSHExecutor.stub!(:new).with(@firewall_ip_address, 'sservice').and_return(mocked_ssh)
      subject.remove
      subject.status.should == :done
    end
  end

  context 'when creating or destroying a rule' do
    before :each do
      @ssh = mock('ssh')
      SSHExecutor.stub!(:new).and_return(@ssh)
      @result = {:status => 0, :out => ''}
    end

    it "should queue a filter rule insertion when created" do
      subject.should_receive(:queue_insertion)
      subject.save
    end

    it "should queue a filter rule removal when destroyed" do
      subject.should_receive(:queue_removal)
      subject.destroy
    end
  end
end

require File.dirname(__FILE__) + '/../spec_helper'

describe UninstallSteps do

  before(:each) do
    @hypervisor_session = mock_session
    HypervisorConnection.stub!(:hypervisor_session).and_return(@hypervisor_session)
    zone = Factory(:zone)
    zone.firewall = Factory(:firewall, :zone => zone)
    @vm = Factory(:installed_vm, :zone => zone)
  end

  it "should only allow uninstall when installed" do
    activated = Factory(:new_vm)
    lambda { activated.uninstall }.should raise_error(InvalidInitialState)
  end

  it "should erase data, delete disks, destroy machine and notify peers when uninstalling" do
    @vm.should_receive(:force_power_off).ordered
    @vm.should_receive(:delete_disks).ordered
    @vm.should_receive(:delete_machine).ordered
    @vm.should_receive(:queue_dhcp_synchronization).ordered
    @vm.should_receive(:delete_firewall_rules).ordered
    @vm.should_receive(:clean_filter_chain).ordered
    @vm.should_receive(:release_ips).ordered
    @vm.should_receive(:notify_uninstall).ordered

    @vm.uninstall

    @vm.status.should be(:uninstalled)
  end

  describe "- individual steps" do

    it 'should release the IPs' do
      @vm.public_ip = Ip.new
      @vm.private_ip = Ip.new

      @vm.release_ips

      @vm.public_ip.should be_nil
      @vm.private_ip.should be_nil
    end

    it 'should destroy all firewall rules associated with the VM' do
      @vm.public_ip = Ip.new(:address => '192.168.0.255')
      @vm.private_ip = Ip.new(:address => '192.168.0.1')

      FirewallRule.without_callbacks do
        @vm.firewall_rules << NatFirewallRule.new(:virtual_machine => @vm)
        @vm.firewall_rules << FilterFirewallRule.new(:virtual_machine => @vm)
  
        @vm.firewall_rules.should_not be_empty

        @vm.delete_firewall_rules
      end

      @vm.firewall_rules.should be_empty
    end
    
    it "should clean filter chain" do
      ssh = mock(:ssh, :exec => {:status => 0})
      SSHExecutor.stub!(:new).and_return(ssh)
      @vm.clean_filter_chain
    end
  end

  describe "- notifications" do

    it "should notify all those needed when the uninstallation is completed" do
      @vm.should_receive(:remove_from_nagios).ordered
      @vm.notify_uninstall
    end

    it "should remove from Nagios" do
      Nagios.should_receive(:remove).with(@vm)
      @vm.send(:remove_from_nagios)
    end

  end

end

require File.dirname(__FILE__) + '/../spec_helper'

describe InstallSteps do

  before :each do
    @hypervisor_session = mock_session
    HypervisorConnection.stub!(:hypervisor_session).and_return(@hypervisor_session)
    @zone = Factory(:zone)
    @firewall = Factory(:firewall)
    @vnc_proxy = Factory(:vnc_proxy, :zone => @zone)
    @account = Factory(:test_account)
    @vm = Factory(:new_vm, :zone => @zone, :account => @account, :password => '^P4ssw0rd$')
  end

  it "should get name and IP, select template, create console, create machine and notify peers when installing" do
    @vm.should_receive(:set_network_to_production).ordered
    @vm.should_receive(:set_network_rate_limit).ordered
    @vm.should_receive(:add_data_disk).ordered
    @vm.should_receive(:queue_dhcp_synchronization).ordered
    @vm.should_receive(:queue_xvp_synchronization).ordered
    @vm.should_receive(:create_vnc_console).ordered
    @vm.should_receive(:create_nat_rule).ordered
    @vm.should_receive(:create_default_filter_rules).ordered
    @vm.should_receive(:power_on).ordered
    @vm.should_receive(:wait_ssh_start_up).ordered
    @vm.should_receive(:change_password).ordered
    @vm.should_receive(:clean_template_files).ordered
    @vm.should_receive(:reboot).ordered
    @vm.should_receive(:notify_install).ordered
    @vm.install
    @vm.status.should be(:installed)
  end

  it "should search the machine template in the zone" do
    the_expected = "213424-123123-12321-12"
    @zone.should_receive(:define_template_uuid_for).with(@vm.system_image).and_return(the_expected)
    @vm.select_template
    @vm.template_uuid.should be(the_expected)
  end

  context "when selecting private ip" do
    it "should select a private ip for the vm" do
      vlan = Vlan.new
      ip = Ip.new
      Vlan.should_receive(:find_for).with(@vm).and_return vlan
      Ip.should_receive(:find_free_private_ip).with(vlan).and_return ip
      @vm.select_private_ip
      @vm.private_ip.should be(ip)
    end

    it "should raise error if can't select vlan" do
      Vlan.should_receive(:find_for).with(@vm).and_return nil

      lambda{@vm.select_private_ip}.should raise_error
    end

    it "should raise error if can't select private ip" do
      vlan = Vlan.new
      Vlan.should_receive(:find_for).with(@vm).and_return vlan
      Ip.should_receive(:find_free_private_ip).with(vlan).and_return nil

      lambda{@vm.select_private_ip}.should raise_error
    end
  end

  describe "- VirtualMachine install" do
    before(:each) do
      @vm.name = "vm_name"
      @vm.public_ip = Factory(:public_ip)
      @vm.template_uuid = "template_uuid"
    end

    it "should set rate limit to 100 Mbps on VM NIC" do
      vm_ref = "OpaqueRef:..."
      @vm.uuid = "5da854d7-7e5e-ce7b-7d12-50db55a12788"
      vif_refs = ["OpaqRef:VIF"]

      @hypervisor_session.VM.should_receive(:get_by_uuid).with(@vm.uuid).and_return(vm_ref)
      @hypervisor_session.VM.should_receive(:get_VIFs).with(vm_ref).and_return(vif_refs)
      @hypervisor_session.VIF.should_receive(:set_qos_algorithm_params).with(vif_refs[0], {'kbps' => '102400'})
      @vm.set_network_rate_limit
    end

    it "should add data disk to machine" do

      storage = Storage.new "STORAGE_0001", "storage_uuid", @zone
      @zone.stub!(:storages).and_return([storage])
      @zone.should_receive(:define_storage_to_data_disk_of).with(@vm).and_return(storage)
      storage.should_receive(:create_data_disk_for).with(@vm)

      @vm.add_data_disk

    end

    context "when waiting until completely boot" do
      before :each do
        @ssh_executor = mock(:ssh)
        SSHExecutor.should_receive(:new).with(@vm.public_ip.address, 'root').and_return(@ssh_executor)
        NephelaeConfig.stub!('[]').with(:vm_ssh_wait_time).and_return(0.5)
        NephelaeConfig.stub!('[]').with(:vm_startup_time).and_return(1)
      end

      it "should raise error if can't connect with ssh after the defined time" do
        @ssh_executor.should_receive(:exec).and_raise "Couldn't connect to vm. Not booted yet"
        lambda{@vm.wait_ssh_start_up}.should raise_error(Timeout::Error)
      end

      it "should return if can connect with ssh" do
        @ssh_executor.should_receive(:exec).and_return({:out => "OK"})
        @vm.wait_ssh_start_up
      end
    end

    context "when encrypting password" do
      it "should generate random salts" do
        salt_a = @vm.send(:salt)
        salt_b = @vm.send(:salt)
        salt_a.should_not == salt_b
      end

      it "should escape the $ symbol" do
        @vm.password = "secret!!"
        @vm.should_receive(:salt).and_return("salt")
        @vm.send(:hash_password).should be('\$1\$salt\$1k1REfMW\/zSK5kfbELE5\.\/')
      end

      it "should raise error if password is not set" do
        @vm.password = nil
        lambda { @vm.send(:hash_password) }.should raise_error
      end
    end

    context "when changing virtual machine root password" do
      before :each do
        @vm.password = "secret!"
        @hashed_password = "$1$salt$hashed_password"
        @vm.should_receive(:hash_password).and_return(@hashed_password)
        @ssh_executor = mock(:ssh)
      end

      context 'when return status is equal to zero' do
        before :each do
          @ssh_executor.should_receive(:exec).with(:change_passwd, {:passwd_hash => @hashed_password}).and_return({:status => 0})
          SSHExecutor.should_receive(:new).with(@vm.public_ip.address, 'root').and_return(@ssh_executor)
        end

        it "should not raise errors" do
          lambda { @vm.change_password }.should_not raise_error
        end

        it "should erase the password on the vm" do
          @vm.change_password
          @vm.reload
          @vm.password.should be_blank
        end
      end

      context 'when return status is different from zero' do
        before :each do
          @ssh_executor.should_receive(:exec).with(:change_passwd, {:passwd_hash => @hashed_password}).and_return({:status => 1})
          SSHExecutor.should_receive(:new).with(@vm.public_ip.address, 'root').and_return(@ssh_executor)
        end

        it "should raise an error" do
          lambda { @vm.change_password }.should raise_error
        end

        it "should not erase the password on the vm" do
          begin
            @vm.change_password
          rescue
          end
          @vm.reload
          @vm.password.should_not be_blank
        end
      end
    end

    context 'when cleaning template files from virtual machine' do
      def set_ssh_executor_result(result)
        @ssh_executor = mock(:ssh)
        @ssh_executor.should_receive(:exec).with(:clean_template_files).and_return(result)
        SSHExecutor.should_receive(:new).with(@vm.public_ip.address, 'root').and_return(@ssh_executor)
      end

      it 'should not raise an error if returned status is equal to zero' do
        set_ssh_executor_result({:status => 0})
        lambda { @vm.clean_template_files }.should_not raise_error
      end

      it 'should raise an error returned status different from zero' do
        set_ssh_executor_result({:status => 1})
        lambda { @vm.clean_template_files }.should raise_error
      end
    end

    it "should change VIF to Production" do
      Vlan.without_callbacks do
        @vm.vlan = Factory(:vlan)
      end

      vm_ref = "OpaqueRef:VM"
      vifs = ["OpaqueRef:VIF"]
      production_network_ref = ["OpaqueRef:network"]

      old_vif_record = {
                    "device" => "0",
                    "network" => "",
                    "VM" => vm_ref,
                    "MAC" => @vm.mac,
                    "MTU" => 0,
                    "other_config" => {},
                    "qos_algorithm_type" => "NICE_QOS",
                    "qos_algorithm_params" => {}
                   }

      vif_record = old_vif_record
      vif_record["network"] = production_network_ref
      new_vif = ["OpaqueRef:NEW_VIF"]

      @hypervisor_session.VM.should_receive(:get_by_uuid).with(@vm.uuid).and_return(vm_ref)
      @hypervisor_session.VM.should_receive(:get_VIFs).with(vm_ref).and_return(vifs)
      @hypervisor_session.VIF.should_receive(:get_record).with(vifs[0]).and_return(old_vif_record)

      @hypervisor_session.network.should_receive(:get_by_name_label).with(@vm.production_network).and_return(production_network_ref)

      #@hypervisor_session.VIF.should_receive(:unplug).with(vifs[0])
      @hypervisor_session.VIF.should_receive(:destroy).with(vifs[0])

      @hypervisor_session.VIF.should_receive(:create).with(vif_record).and_return(new_vif)
      #@hypervisor_session.VIF.should_receive(:plug).with(new_vif)

      @vm.set_network_to_production
    end

    it "should create virtual machine's nat rule" do
      NatFirewallRule.should_receive(:create!).with(:virtual_machine => @vm)
      @vm.create_nat_rule
    end

    it "should create virtual machine's default filter rules" do
      ports = NephelaeConfig[:opened_ports]
      ports.each { |port| FilterFirewallRule.should_receive(:create!).with(:virtual_machine => @vm, :filter_port => port, :filter_protocol => :tcp)}

      @vm.create_default_filter_rules
    end

    it "should create virtual machine's VNC console" do
      VncConsole.should_receive(:create!).with(:virtual_machine => @vm, :vnc_proxy => @vm.zone.vnc_proxy)
      @vm.create_vnc_console
    end

  end

  describe "- notifications" do

    it "should notify all those needed when the installation is completed" do
      @vm.should_receive(:insert_on_nagios).ordered
      @vm.notify_install
    end

    it "should change status on Server Registry" do
      response = Net::HTTPResponse.new('dummy', 200, 'dummy')
      ServerRegistry.should_receive(:update_status).with(@vm).and_return(response)

      @vm.send(:confirm_installation_to_server_registry)
    end

    it "should raise an excetion when can't change status on Server Registry" do
      response = Net::HTTPResponse.new('dummy', 400, 'dummy')
      ServerRegistry.should_receive(:update_status).with(@vm).and_return(response)

      lambda { @vm.send(:confirm_installation_to_server_registry) }.should raise_error(
        "Fail to set status. Server Registry returned: #{response.inspect}")
    end

    it "should insert on Nagios" do
      Nagios.should_receive(:insert).with(@vm)
      @vm.send(:insert_on_nagios)
    end

  end

  private
  def mock_server_registry
    mock_service :post => "/seam/resource/ws/server", :port => 9999 do |head, body|
      head['Content-Type'] = "application/vnd.locaweb.Server-1.0+xml"
      body.write <<-EOF
          <?xml version="1.0" encoding="UTF-8"?>
          <server>
            <name>TXXXCNN0001</name>
            <managementType>G0</managementType>
            <status>INSTALLING</status>
            <serviceType>Servidor em Grid</serviceType><virtualType>
              <parent>HM852</parent>
            </virtualType>
            <interfaces>
              <interface name="eth" number="0">
                <mac></mac>
                <ips>
                    <ip>
                      <address>10.11.2.116</address>
                      <mainIP>true</mainIP>
                      <gateway>10.11.2.1</gateway>
                      <network>10.11.2.0</network>
                      <broadcast>10.11.2.255</broadcast>
                      <netmask>255.255.255.0</netmask>
                      <vlan>1</vlan>
                    </ip>
                </ips>
              </interface>
            </interfaces>
            <operatingSystem>LICENCA_LIX_CENTOS_5</operatingSystem>
            <applications>
            </applications>
          </server>
      EOF
    end
  end
end

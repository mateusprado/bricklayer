require File.dirname(__FILE__) + '/../spec_helper'

describe VirtualMachine do
  before :all do
    @system_image = Factory(:centos)
    @zone = Factory(:zone)
    @account = Factory(:client_account)
  end

  after :all do
    @system_image.destroy
    @zone.destroy
    @account.destroy
  end

  should_belong_to :system_image
  should_belong_to :zone
  should_belong_to :vlan
  should_belong_to :account
  should_belong_to :public_ip, :class_name => 'Ip'
  should_belong_to :private_ip, :class_name => 'Ip'
  should_have_many :firewall_rules, :dependent => :destroy
  should_have_many :snapshots, :dependent => :destroy
  should_have_many :filter_rules, :class_name => "FilterFirewallRule"
  should_have_one :console, :class_name => "VncConsole"
  
  should_validate_presence_of :system_image, :cpus, :hdd, :memory, :account
  should_validate_numericality_of :cpus, :hdd, :memory
  should_validate_acceptance_of :terms

	should_have_scope :with_assigned_ip, :joins => :public_ip
  should_have_scope :awaiting_validation, :conditions => {:status => :awaiting_validation}
  should_have_scope :not_awaiting_validation, :conditions => ["status <> ?", :awaiting_validation]
  should_have_scope :not_uninstalled, :conditions => ["status <> ?", :uninstalled]

  context 'after initializing a new vm' do
    it 'should have a default status of :awaiting_validation' do
      subject.memory.should == 0
    end

    it 'should have a default memory value of zero' do
      subject.memory.should == 0
    end

    it 'should have a default hdd value of zero' do
      subject.hdd.should == 0
    end

    it 'should have a default cpus value of zero' do
      subject.cpus.should == 0
    end
  end

  context 'when evaluating a new vm' do
	  before :each do
      @vm = Factory.build(:new_vm, :uuid => 'abcd-abcd', :cpus => 1, :hdd => 10, :memory => 1024)
    end

    it "should require public uuid to be filled in" do
      @vm.stub!(:generate_public_uuid).and_return(nil)
      @vm.update_attribute :public_uuid, nil
      @vm.should have(1).error_on(:public_uuid)
    end

    it "should require a good/strong password" do
      @vm.password = "abc123"
      @vm.should_not be_valid

      @vm.should have(1).error_on(:password)
    end

    it "should require password to be confirmed" do
      @vm.password = "^P4ssw0rd$"
      @vm.password_confirmation = "invalid"

      @vm.should_not be_valid
      @vm.should include_error_message_for(:password, :confirmation)
    end
    
    it "should allow new vms with blank name" do
      @vm.name = nil
      @vm.should be_valid
    end
    
    it "should allow vms with blank names only until select_name step"

    context "with the exactly minimum configuration" do
      it "should be valid" do
        @vm.system_image = Factory(:system_image_with_minimum_configuration)
        @vm.memory = @vm.system_image.minimum_memory
        @vm.hdd = @vm.system_image.minimum_hdd
        @vm.cpus = @vm.system_image.minimum_cpus

        @vm.should be_valid
      end
    end

    context "before saving, if the vm doesn't have the minimum specs defined on the system image" do
      before :each do
        @vm.system_image = Factory(:system_image_with_minimum_configuration)
      end

      it 'should not be valid' do
        @vm.should_not be_valid
      end

      it "should include an error on cpus if it's less than the required minimum" do
        @vm.should include_error_message_for(:cpus, :greater_than_or_equal_to, :count => @vm.system_image.minimum_cpus)
      end

      it "should include an error on hdd if it's less than the required minimum" do
        @vm.should include_error_message_for(:hdd, :greater_than_or_equal_to, :count => @vm.system_image.minimum_hdd)
      end

      it "should include an error on memory if it's less than the required minimum" do
        @vm.should include_error_message_for(:memory, :greater_than_or_equal_to, :count => @vm.system_image.minimum_memory)
      end
    end

    it 'should have a priority equal to the product of its cpu and memory definitions' do
      @vm.memory = 2048
      @vm.cpus = 2
      @vm.priority.should == (2048 * 2)
    end

    it 'should publish a message to Installer consumer when asking for queue installation' do
      Installer.should_receive(:publish).with(:virtual_machine_id => @vm.id)
      @vm.queue_installation
    end

    it 'should publish a message to DHCP Synchronizer consumer when asking for dhcp synchronization' do
      DHCPSynchronizer.should_receive(:publish)
      @vm.should_receive(:log_activity)
      @vm.queue_dhcp_synchronization
    end
    
    it 'should not return vm with no assigned ip' do
      @vm.public_ip = nil
      @vm.save
      VirtualMachine.vms_not_uninstalling_and_with_assigned_ip.should be([])
    end
    
    it 'should not return vm in uninstall process' do
      @vm.status = :uninstalled
      @vm.public_ip = Factory(:public_ip)
      @vm.save
      VirtualMachine.vms_not_uninstalling_and_with_assigned_ip.should be([])
    end
    
    it 'should returned vm not in uninstall process and with assigned ip' do
      @vm.status = :installed
      @vm.public_ip = Factory(:public_ip)
      @vm.save
      VirtualMachine.vms_not_uninstalling_and_with_assigned_ip.should_not be([])
    end
    
    it 'should publish a message to TemplateCloner consumer when asking for queue template cloning' do
      TemplateCloner.should_receive(:publish).with(:virtual_machine_id => @vm.id)
      @vm.queue_template_clone
    end
  end

  context 'before the machine is created' do
    it "should try to choose a zone" do
      vm = Factory.build(:awaiting_validation_vm, :system_image => @system_image)
      vm.should_receive(:choose_zone)
      vm.save
    end

    it 'should rely on the account to choose the proper zone' do
      subject.account = Factory(:test_account)
      subject.send :choose_zone
      subject.zone.should == Zone.first
    end

    it "should raise an error if it doesn't have an account set" do
      subject.account.should be_nil
      lambda{ subject.send(:choose_zone) }.should raise_error
      subject.zone.should be_nil
    end

    it "should keep any zone set before saving and not call zone resolving method on account" do
      subject.zone = Zone.new
      subject.should_not_receive(:account)
      lambda{ subject.send(:choose_zone) }.should_not raise_error
    end
  end

  it "should generate a public uuid before its validation" do
    vm = Factory.build(:awaiting_validation_vm, :system_image => @system_image)
    vm.save
    vm.public_uuid.should_not be_empty
  end

  it "should not override any existing public uuid" do
    vm = Factory(:valid_vm)
    lambda { vm.update_attribute(:cpus, 1) }.should_not change(vm, :public_uuid)
  end

  it 'should be able to generate a valid UUID' do
    vm = VirtualMachine.new
    vm.send :generate_public_uuid
    vm.public_uuid.should match(VirtualMachine::VALID_UUID)
  end

  it 'should try to queue the installation setup when creating a new machine with :awaiting_validation step' do
    vm = Factory.build(:awaiting_validation_vm, :system_image => @system_image)
    vm.should_receive(:queue_installation_setup)
    vm.save
  end

  it 'should add the machine to the InstallationSetup queue when called queue_installation_setup' do
    subject.system_image = @system_image
    InstallationSetup.should_receive(:publish).with({:virtual_machine_id => subject.to_param})
    subject.send(:queue_installation_setup)
  end

  context 'when creating a new machine for a limited account, it should generate errors when exceding the' do
    before :each do
      limited_account = Factory(:limited_account)
      @vm = Factory.build(:awaiting_validation_vm, :system_image => @system_image, :account => limited_account)
      Factory(:uninstalled_vm, :system_image => @system_image, :account => limited_account)
      Factory(:installed_vm, :system_image => @system_image, :account => limited_account)
      limited_account.current_machine_count.should be(1)
    end

    it 'number of activated machines' do
      @vm.should include_error_message_for(:base, :exceeded_maximum_machines, :count => 1)
    end

    it 'maximum memory per machine' do
      @vm.memory = 5 * 1024
      @vm.should include_error_message_for(:memory, :exceeded_maximum_memory, :limit => (4 * 1024))
    end

    it 'maximum hdd per machine' do
      @vm.hdd = 100
      @vm.should include_error_message_for(:hdd, :exceeded_maximum_hdd, :limit => 80)
    end

    it 'maximum cpus per machine' do
      @vm.cpus = 6
      @vm.should include_error_message_for(:cpus, :exceeded_maximum_cpus, :limit => 4)
    end
  end

  it 'should return its assigned firewall' do
    VirtualMachine.without_callbacks do
      vm = Factory(:new_vm, :system_image => @system_image, :zone => @zone)
      vm.firewall.should be(vm.zone.firewall)
    end
  end

  it 'should return its assigned firewall' do
    VirtualMachine.without_callbacks do
      vm = Factory(:new_vm, :system_image => @system_image, :zone => @zone)
      vm.firewall.should be(vm.zone.firewall)
    end
  end

  it 'should be installing' do
    VirtualMachine.new(:status => :not_created).should be_installing
    VirtualMachine.new(:status => :with_production_network).should be_installing
  end

  it 'should be configuring' do
    VirtualMachine.new(:status => :awaiting_validation).should be_configuring
  end

  it "should be installed" do
    VirtualMachine.new(:status => :installed).should be_installed
  end

  it "should be uninstalling" do
    VirtualMachine.new(:status => VirtualMachine::UNINSTALL_STATUSES.first).should be_uninstalling
  end

  it "should be uninstalled" do
    VirtualMachine.new(:status => :uninstalled).should be_uninstalled
  end

  context "json serialization" do
    before do
      @vm = Factory(:valid_vm)
      @json = HashWithIndifferentAccess.new ActiveSupport::JSON.decode(@vm.to_json)
    end

    it "should include configuring" do
      @json[:virtual_machine][:configuring].should == @vm.configuring?
    end

    it "should include errors" do
      @json[:virtual_machine][:errors].should be_kind_of(Array)
    end

    it "should include installed" do
      @json[:virtual_machine][:installed].should == @vm.installed?
    end

    it "should include installing" do
      @json[:virtual_machine][:installing].should == @vm.installing?
    end
  end

  context '- consulting xen:' do
    before(:each) do
      hypervisor_session = mock_session
      HypervisorConnection.stub!(:hypervisor_session).and_return(hypervisor_session)
      @vm = Factory(:installed_vm, :zone => @zone, :system_image => @system_image, :account => @account)
    end

    it 'should return the host where it resides' do
      host = Factory(:host)

      vm_ref = 'OpaqueRef:VM'
      host_ref = 'OpaqueRef:Host'

      @vm.hypervisor_session.VM.should_receive(:get_by_uuid).with(@vm.uuid).and_return(vm_ref)
      @vm.hypervisor_session.VM.should_receive(:get_resident_on).with(vm_ref).and_return(host_ref)
      @vm.hypervisor_session.host.should_receive(:get_name_label).and_return(host.name)
      @vm.host.should == host
    end

    context "when dealing with snapshots" do

      it "should revert to a snapshot" do
        snapshot = Snapshot.new
        @vm.should_receive(:force_power_off).ordered
        @vm.should_receive(:use_cloned_disks_from).with(snapshot).ordered
        @vm.should_receive(:power_on).ordered
        @vm.revert_to(snapshot)
      end

      it "should use snapshot disks" do
        snapshot = Snapshot.new
        vbd_refs = ["OpaqueRef:VBD1", "OpaqueRef:VBD2"]
        vbd_records = [{"type" => "Disk"}, {"type" => "CD"}]

        @vm.should_receive(:delete_disks)
        @vm.hypervisor_session.VM.should_receive(:get_by_uuid).with(@vm.uuid)
        @vm.hypervisor_session.VM.should_receive(:get_by_uuid).with(snapshot.uuid)
        @vm.hypervisor_session.VM.should_receive(:get_record).and_return({'VBDs' => vbd_refs})
        2.times{|i| @vm.hypervisor_session.VBD.should_receive(:get_record).with(vbd_refs[i]).and_return(vbd_records[i])}
        @vm.hypervisor_session.VDI.should_receive(:clone)
        @vm.hypervisor_session.VBD.should_receive(:create)
        @vm.send(:use_cloned_disks_from, snapshot)
      end
    end
  end

  context 'when requesting graphs' do
    before(:each) do
      host = Factory(:host)
      @vm = Factory(:installed_vm, :zone => @zone, :system_image => @system_image, :account => @account)
      @vm.stub!(:host).and_return(host)

      @base_path = File.join('vm', "#{@vm.public_uuid}")

      rrd_xml_mock_file = File.join(Rails.root, "spec", "templates", "vm_rrd_mock.xml")
      HTTParty.should_receive(:get).and_return(File.open(rrd_xml_mock_file, 'r') {|f| f.read})
    end

    it 'should return the graph image for cpu' do
      expected_cpu_graph_path = File.join(@base_path, "cpu.png")
      @vm.cpu_graph_path.should be(expected_cpu_graph_path)

      File.exist?(File.join(Rails.public_path, "images", @vm.cpu_graph_path)).should be_true
    end

    it 'should return the graph image for memory' do
      expected_memory_graph_path = File.join(@base_path, "memory.png")

      @vm.memory_graph_path.should == expected_memory_graph_path
      File.exist?(File.join(Rails.public_path, "images", @vm.memory_graph_path)).should be_true
    end

    it 'should return the graph image for io' do
      hypervisor_session = mock_session
      HypervisorConnection.stub!(:hypervisor_session).and_return(hypervisor_session)

      vm_ref = 'OpaqueRef:VM'
      vm_record = {'VBDs' => ['OpaqueRef:VBD1', 'OpaqueRef:VBD2']}
      vbd1_record = {'type' => 'CD', 'device' => 'xvdd'}
      vbd2_record = {'type' => 'Disk', 'device' => 'xvda'}

      @vm.hypervisor_session.VM.should_receive(:get_by_uuid).with(@vm.uuid).and_return(vm_ref)
      @vm.hypervisor_session.VM.should_receive(:get_record).with(vm_ref).and_return(vm_record)

      @vm.hypervisor_session.VBD.should_receive(:get_record).with(vm_record['VBDs'][0]).and_return(vbd1_record)
      @vm.hypervisor_session.VBD.should_receive(:get_record).with(vm_record['VBDs'][1]).and_return(vbd2_record)

      expected_io_graph_path = File.join(@base_path, "io.png")
      @vm.io_graph_path.should be(expected_io_graph_path)

      File.exist?(File.join(Rails.public_path, "images", @vm.io_graph_path)).should be_true
    end
  end
  
  context 'when logging virtual machine activity' do
    before(:each) do
      @vm = Factory(:valid_vm)
    end
    
    it 'should log simple activities' do
      @vm.log_activity(:debug, "Logging debug")
      @vm.activities.last.level.should be("debug")
      @vm.activities.last.message.should be("Logging debug")    
    end
    
    it 'should log exceptions' do
      e = Exception.new("New Exception")
      @vm.log_activity(:error, e)
      @vm.activities.last.level.should be("error")
      @vm.activities.last.message.should be("New Exception")
      @vm.activities.last.backtrace.should be nil
    end
    
    it 'should log raised blocks as error' do
      begin
        @vm.log_activity do
          raise "New error log when passing a raise block"
        end
      rescue
        @vm.activities.last.level.should be("error")
        @vm.activities.last.message.should be("New error log when passing a raise block")
      end      
    end
  end
  
end

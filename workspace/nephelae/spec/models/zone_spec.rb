require File.dirname(__FILE__) + "/../spec_helper"

describe Zone do
  before(:each) do
    @hypervisor_session = mock_session
  	HypervisorConnection.stub!(:hypervisor_session).and_return(@hypervisor_session)
  end

  should_validate_presence_of :name, :number
  should_validate_numericality_of :number, :greater_than_or_equal_to => Zone::MINIMUM, :less_than_or_equal_to => Zone::MAXIMUM

  should_have_many :hosts, :autosave => true, :dependent => :destroy
  should_have_many :matrix_machines, :dependent => :destroy
  should_have_many :virtual_machines, :dependent => :nullify
  should_have_many :vlans, :autosave => true, :dependent => :destroy
  should_have_one :firewall, :dependent => :destroy
  should_have_one :vnc_proxy, :dependent => :destroy

  context "when it's a valid object" do
    subject { Factory(:zone) }

    it "should have 900 vlans, from 1101 to 2000, with /27 mask on its creation" do
      # Supressing :create_range to speed up the tests
      Vlan.without_callbacks(:create_range) do
        subject.generate_vlans
        subject.should have(900).vlans
        subject.vlans.first.number.should be(1101)
        subject.vlans.last.number.should be(2000)
      end
    end

    it "should have the maximum number of hosts allowed" do
      subject.maximum_hosts.should be(16)
    end
    
    it "should have the maximum number of hosts in use at any given time" do
      subject.maximum_hosts_in_use.should be(15)
    end

    it "should have a upgrade slack" do
      subject.upgrade_slack.should be(0.1)
    end

    it "should have a total memory available when empty" do
      subject.total_memory.should be(12 * 4096 * subject.maximum_hosts)
    end

    it "should calculate the allocable memory based on total_memory, maximum_hosts, maximum_hosts_in_use and upgrade_slack" do
      subject.allocable_memory.should be(subject.total_memory * (subject.maximum_hosts_in_use/subject.maximum_hosts) * (1 - subject.upgrade_slack))
    end

    it "should have a positive allocable_memory value" do
      subject.allocable_memory.should > 0
    end

    context "when it have installed vms" do
      before :each do
        sample_account = Factory(:client_account)
        subject.virtual_machines << Factory(:new_vm, :zone => subject, :account => sample_account, :memory => 1024)
        @sample_vm = Factory(:new_vm, :zone => subject, :account => sample_account, :memory => 4096)
        subject.virtual_machines << @sample_vm

        another_account = Factory(:test_account)
        subject.virtual_machines << Factory(:new_vm, :zone => subject, :account => another_account, :memory => 2048)

        VirtualMachine.without_callbacks do
          subject.virtual_machines << Factory(:awaiting_validation_vm, :zone => subject, :account => sample_account, :memory => 2048)
        end
      end

      it "should have the used memory given the installed vms" do
        records = {
          "OpaqRef1" => {'memory_dynamic_max' => '1073741824', 'is_a_template' => false, 'is_a_snapshot' => false},
          "OpaqRef2" => {'memory_dynamic_max' => '6442450944', 'is_a_template' => false, 'is_a_snapshot' => false},
          "OpaqRef3" => {'memory_dynamic_max' => '6442450944', 'is_a_template' => true, 'is_a_snapshot' => false},
          "OpaqRef4" => {'memory_dynamic_max' => '6442450944', 'is_a_template' => false, 'is_a_snapshot' => true}
        }
        
        @hypervisor_session.VM.should_receive(:get_all_records).and_return(records)
        subject.used_memory.should be(1024 * 7)
      end

      it "should calculate the available memory based on allocable_memory and used_memory" do
        subject.stub!(:used_memory).and_return(2048)
        subject.available_memory.should be(subject.allocable_memory - subject.used_memory)
      end

      it "should return the number of running machines for a given account" do
        subject.running_machines_for(@sample_vm.account).should be(2)
      end

      it "should be able to accomodate another machine if didn't reach maximum number of running machines for the account and has enough available memory" do
        subject.stub!(:used_memory).and_return(2048)
        subject.can_accomodate_machine?(@sample_vm).should be_true
      end

      it "should not be able to accomodate another machine if reached maximum number of running machines for the account" do
        subject.stub!(:used_memory).and_return(2048)
        subject.should_receive(:running_machines_for).with(@sample_vm.account).and_return(30)
        subject.can_accomodate_machine?(@sample_vm).should be_false
      end
    end

    it "should know its master host" do
      the_master = Factory(:master, :zone => subject)
      subject.hosts << the_master
      master = subject.master!
      master.should_not be_nil
      master.should be(the_master)
    end
    
    it "should return a new_record as master if there isn't one" do
      master = subject.master
      master.should_not be_nil
      master.should be_new_record
    end
    
    it "should build its own master and cache it" do
      host = Factory.attributes_for(:host)
      subject.master_attributes = host
      master = subject.master
      master.should_not be_nil
      master.ip.should be(host[:ip])
      subject.master.should be_equal(master)
    end

    it "should return its assigned firewall" do
      zone = Factory(:zone)
      firewall = Factory(:firewall, :zone => zone)
      zone.firewall.should be(firewall)
    end

    it "should return its assigned vnc_proxy" do
      zone = Factory(:zone)
      vnc_proxy = Factory(:vnc_proxy, :zone => zone)
      zone.vnc_proxy.should be(vnc_proxy)
    end

    it "should return only valid storages" do
      storages_ref = ["OpaqueRef:1","OpaqueRef:2","OpaqueRef:3","OpaqueRef:4"]
      storages_record = [
        {"name_label" => "ISO", "uuid" => "123", "type" => "iso"},
        {"name_label" => "Local", "uuid" => "124", "type" => "lvm"},
        {"name_label" => "Valid1", "uuid" => "125", "type" => "nfs"},
        {"name_label" => "Valid2", "uuid" => "126", "type" => "nfs"},
        {"name_label" => "CD Drive", "uuid" => "127", "type" => "udv"},
      ]
      
      @hypervisor_session.SR.should_receive(:get_all).and_return(storages_ref)
      
      (0..3).each do |index|
        @hypervisor_session.SR.should_receive(:get_record).with(storages_ref[index]).and_return(storages_record[index])
      end
      
      storages = subject.storages
      storages.size.should be(2)
      storages.first.name.should be("Valid1")
      storages.last.name.should be("Valid2")
    end

    it "should save zone hosts" do
    	@master = Factory(:master, :zone => subject)
    	subject.hosts << @master
    	subject.save
    
    	host_refs = ["OpaqueRef:HOST1", "OpaqueRef:HOST_MASTER"]
    	host = { "name_label" => "HOST1", "address" => "10.11.0.11" }
    	master = { "name_label" => @master.name, "address" => @master.ip }
    
    	@hypervisor_session.host.should_receive(:get_all).and_return(host_refs)
    	@hypervisor_session.host.should_receive(:get_record).twice.and_return(host, master)
    	
    	subject.save_and_update_hosts.should be_true
    	
    	subject.should have(2).hosts
    end
  end
  
  describe "- Template selection" do
    subject { Factory.create(:zone) }
    
    before(:each) do
      @centos = Factory(:centos)
      @matrix = Factory(:matrix, :system_image => @centos)
      @win = Factory(:win_2k3)
      
      subject.matrix_machines << @matrix
    end
    
    it "should select existing template when it has less than 20 copies" do
      template_uuid = subject.define_template_uuid_for @centos
      template_uuid.should be("template_uuid")
    end
    
    it "should select template through matrix for the required system image" do
      win_matrix = Factory(:win_matrix, :system_image => @win)
      subject.matrix_machines << win_matrix
      
      template_uuid = subject.define_template_uuid_for @win
      template_uuid.should be("win_template_uuid")
    end
    
    it "should raise error if there is no matrix for the required system image" do
      lambda { subject.define_template_uuid_for @win }.should raise_error(
        "The zone #{subject.name} has no matrix machine for the given system image: #{@win.code}")
    end
    
    it "should create a new template when there is none" do      
    	win_matrix = Factory(:win_matrix, :system_image => @win, :template_uuid => nil)
      subject.matrix_machines << win_matrix
      
      subject.should_receive(:create_template_from).with(win_matrix).and_return("new_template_uuid")
      subject.define_template_uuid_for(@win).should be("new_template_uuid")
    end
    
    it "should create template from matrix" do
      win_matrix = Factory(:win_matrix, :system_image => @win, :template_uuid => nil)
      subject.matrix_machines << win_matrix
      
      subject.should_receive(:define_storage_to_template_of).with(win_matrix).and_return("storage_uuid")
      subject.should_receive(:create_template_on_storage_from).with(win_matrix, "storage_uuid").and_return("new_template_uuid")
      
      subject.send(:create_template_from, win_matrix).should be("new_template_uuid")
    end
    
    it "should create template from matrix on storage" do
      sr = ["OpaqueRef:..."]
      vm_matrix = ["OpaqueRef:..."]
      matrix_copy = ["OpaqueRef:..."]
      
      storage = Storage.new( "storage", "storage_uuid", subject)
      
      @hypervisor_session.SR.should_receive(:get_by_uuid).with(storage.uuid).and_return(sr)
      @hypervisor_session.VM.should_receive(:get_by_uuid).with(@matrix.uuid).and_return(vm_matrix)
      @hypervisor_session.VM.should_receive(:copy).and_return(matrix_copy)
      @hypervisor_session.VM.should_receive(:set_is_a_template).with(matrix_copy, true)
      @hypervisor_session.VM.should_receive(:get_uuid).with(matrix_copy).and_return("template_uuid")
      
      template_uuid = subject.send(:create_template_on_storage_from, @matrix, storage)
      
      @matrix.template_uuid.should be("template_uuid")
      @matrix.reload
      @matrix.template_uuid.should_not be_blank
      @matrix.template_copies.should be(0)
      template_uuid.should be(@matrix.template_uuid)
    end
    
    it "should select storage for matrix copy to create templates" do
      matrix = ["OpaqueRef:..."]
      matrix_record= {"physical_size" => 500}

      expected_storage_uuid = "less_used_storage_uuid"
      
      @hypervisor_session.VM.should_receive(:get_by_uuid).and_return(matrix)
      @hypervisor_session.VM.should_receive(:get_record).and_return(matrix_record)
      subject.should_receive(:define_less_used_storage).with(matrix_record["physical_size"]).and_return(expected_storage_uuid)
      subject.send(:define_storage_to_template_of, @matrix).should be(expected_storage_uuid)
    end

    it "should raise error if there is no storage for the required matrix" do
      matrix = ["OpaqueRef:..."]
      matrix_record= {"physical_size" => 500}

      expected_storage_uuid = "less_used_storage_uuid"
      
      @hypervisor_session.VM.should_receive(:get_by_uuid).and_return(matrix)
      @hypervisor_session.VM.should_receive(:get_record).and_return(matrix_record)
      subject.should_receive(:define_less_used_storage).with(matrix_record["physical_size"]).and_return(nil)
      
      lambda { subject.send(:define_storage_to_template_of, @matrix) }.should raise_error(
        "There is no storage available on zone #{subject.name} to create template")
    end

    it "should select storage for machine data disk" do
      vm = Factory(:new_vm, :system_image => @centos, :hdd => 50)

      expected_storage_uuid = "less_used_storage_uuid"
      
      subject.should_receive(:define_less_used_storage).with(vm.hdd).and_return(expected_storage_uuid)
      subject.send(:define_storage_to_data_disk_of, vm).should be(expected_storage_uuid)
    end
    
    it "should raise error if there is no storage for the required machine" do
      vm = Factory(:new_vm, :system_image => @centos, :hdd => 50)

      expected_storage_uuid = "less_used_storage_uuid"
      
      subject.should_receive(:define_less_used_storage).with(vm.hdd).and_return(nil)
      
      lambda { subject.send(:define_storage_to_data_disk_of, vm) }.should raise_error(
        "There is no storage available on zone #{subject.name} to create the machine data disk")
    end

    it "should select storage based on a size" do
      
      storage1 = Storage.new "STORAGE_0001", "storage_uuid", subject
      storage2 = Storage.new "STORAGE_0002", "second_storage_uuid", subject
      subject.stub!(:storages).and_return([storage1, storage2])
      
      
      disk_size = 500
      sr = ["OpaqueRef:..."]
      sr_record= {"virtual_allocation" => 500000, "physical_size" => 100000}
      second_sr_record= {"virtual_allocation" => 500000, "physical_size" => 1000000}
      
      @hypervisor_session.SR.should_receive(:get_by_uuid).twice.and_return(sr)
      @hypervisor_session.SR.should_receive(:get_record).twice.and_return(sr_record, second_sr_record)
      subject.send(:define_less_used_storage, disk_size).should be(storage2)
    end
    
    it "should return nil when no storage is available" do
      
      storage1 = Storage.new "STORAGE_0001", "storage_uuid", subject
      storage2 = Storage.new "STORAGE_0002", "second_storage_uuid", subject
      subject.stub!(:storages).and_return([storage1, storage2])
      
      disk_size = 5000000
      sr = ["OpaqueRef:..."]
      sr_record= {"virtual_allocation" => 500000, "physical_size" => 100000}
      second_sr_record= {"virtual_allocation" => 500000, "physical_size" => 1000000}
      
      @hypervisor_session.SR.should_receive(:get_by_uuid).twice.and_return(sr)
      @hypervisor_session.SR.should_receive(:get_record).twice.and_return(sr_record, second_sr_record)
      subject.send(:define_less_used_storage, disk_size).should be(nil)
    end

    it "should delete a existing template and create a template when it has more than 20 copies" do
      matrix = Factory(:win_matrix, :system_image => @win, :template_copies => 20)
      subject.matrix_machines << matrix
      old_template_uuid = matrix.template_uuid
      
      subject.should_receive(:delete_template_from).with(matrix)
      subject.should_receive(:create_template_from).with(matrix).and_return("new_template_uuid")
      subject.define_template_uuid_for @win
    end
  
    it "should delete a existing template" do
      
      template = ["OpaqueRef:..."]
      
      @hypervisor_session.VM.should_receive(:get_by_uuid).and_return(template)
      @hypervisor_session.VM.should_receive(:destroy).with(template).and_return(success_response)  
      subject.send(:delete_template_from, @matrix)
      @matrix.template_copies.should be 0
    end
  end
  
  context "when saving and update hosts fails" do
    subject { Factory.create(:zone) }

    before :each do
    	@master = Factory(:master, :zone => subject)
    	subject.hosts << @master
    	subject.save
    
    	@host_refs = ["OpaqueRef:HOST1", "OpaqueRef:HOST_MASTER"]
    end

    context "with standard errors" do
      before :each do
      	@hypervisor_session.host.should_receive(:get_all).and_return(@host_refs)
      	@hypervisor_session.host.should_receive(:get_record).and_return {raise "Error inside transaction"}
      end

      it "should return false" do
      	subject.save_and_update_hosts.should be_false
      end

      it "should keep previous state" do
      	subject.save_and_update_hosts

      	loaded_zone = Zone.find(subject.id)
      	loaded_zone.should have(1).host
      	loaded_zone.hosts.first.should be(@master)
      end

      it "should log standard errors" do
      	subject.save_and_update_hosts
      	subject.errors.on(:master).should be("Couldn't update all zone hosts: Error inside transaction")
      end

      it "should have only one message" do
      	subject.save_and_update_hosts
      	subject.errors.on(:master).should_not be_a(Array)
      end
    end

    context "with active record errors" do
      before :each do
      	@hypervisor_session.host.should_receive(:get_all).and_return(@host_refs)
      	@hypervisor_session.host.should_receive(:get_record).and_return({})
      end

      it "should record all error messages returned by an invalid ActiveRecord object" do
      	subject.save_and_update_hosts
      	subject.errors.on(:master).should be_a(Array)
      end
    end
  end
  
end

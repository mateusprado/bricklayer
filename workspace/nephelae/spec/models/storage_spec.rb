require File.dirname(__FILE__) + '/../spec_helper'

describe Storage do
  it "should allow overselling"
  
  describe "- Disk creation" do
  
    before(:each) do
      @hypervisor_session = mock_session
      HypervisorConnection.stub!(:hypervisor_session).and_return(@hypervisor_session)
      zone = Factory(:zone)
      @storage = Storage.new "STORAGE_0001", "storage_uuid", zone
      zone.stub!(:storages).and_return([@storage])

      @system_image = Factory(:centos)
      @vm = Factory(:new_vm, :name => "NEW_VM", :system_image => @system_image)
    end
    
    it "should create a disk for the vm" do
    
      vdi_uuid = "vdi_uuid"
      @storage.should_receive(:create_VDI_for).with(@vm).and_return(vdi_uuid)
      @storage.should_receive(:create_VBD_for).with(@vm, vdi_uuid)
      
      @storage.create_data_disk_for(@vm)
    end
    
    it "should create the VDI" do
      
      name_label = "#{@vm.name} DISK"
      name_description = name_label
      storage_ref = "OpaqRef:SR"
      virtual_size = (@vm.hdd * 1024 * 1024 * 1024).to_s		#GB To B
      type = "system"
      sharable = false
      read_only = false
      other_config = {}
      xenstore_data = {}
      sm_config = {}
      tags = []
      
      parameters = {
                    :name_label => name_label,
                    :name_description => name_description,
                    :SR => storage_ref,
                    :virtual_size => virtual_size,
                    :type => type,
                    :sharable => sharable,
                    :read_only => read_only,
                    :other_config => other_config,
                    :xenstore_data => xenstore_data,
                    :sm_config => sm_config,
                    :tags => tags
                  }
      
      expected_vdi_ref = "OpaqRef:VDI"
      expected_vdi_uuid = "aedf-0123-2345-a345"
      
      expected_vdi_record = {"uuid" => expected_vdi_uuid}
      
      @hypervisor_session.SR.should_receive(:get_by_uuid).with(@storage.uuid).and_return(storage_ref)
      @hypervisor_session.VDI.should_receive(:create).with(parameters).and_return(expected_vdi_ref)
                                               
      @hypervisor_session.VDI.should_receive(:get_record).with(expected_vdi_ref).and_return(expected_vdi_record)
      @storage.send(:create_VDI_for, @vm).should be(expected_vdi_uuid)
    end
    
    it "should create the VBD" do
      vm_ref = "OpaqRef:VM"
      vdi_uuid = "vdi_uuid"
      vdi_ref = "OpaqRef:VDI"
      userdevice = "1"
      bootable = false
      mode = "RW"
      type = "Disk"
      unpluggable = false
      empty = false
      other_config = {}
      qos_algorithm_type = ""
      qos_algorithm_params = {}
      
      parameters = {
                    :VM => vm_ref,
                    :VDI => vdi_ref,
                    :userdevice => userdevice,
                    :bootable => bootable,
                    :mode => mode,
                    :type => type,
                    :unpluggable => unpluggable,
                    :empty => empty,
                    :other_config => other_config,
                    :qos_algorithm_type => qos_algorithm_type,
                    :qos_algorithm_params => qos_algorithm_params
                  }
      
      expected_vbd = "OpaqRef:..."
      
      @hypervisor_session.VM.should_receive(:get_by_uuid).with(@vm.uuid).and_return(vm_ref)
      @hypervisor_session.VDI.should_receive(:get_by_uuid).with(vdi_uuid).and_return(vdi_ref)
      @hypervisor_session.VBD.should_receive(:create).with(parameters).and_return(expected_vbd)
      
      @storage.send(:create_VBD_for, @vm, vdi_uuid)
    end
  end
  
end

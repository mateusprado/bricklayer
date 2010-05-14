require File.dirname(__FILE__) + '/../spec_helper'

describe CloneFromTemplateSteps do

  before(:each) do
    @hypervisor_session = mock_session
    HypervisorConnection.stub!(:hypervisor_session).and_return(@hypervisor_session)
    @zone = Factory(:zone)
    account = Factory(:test_account)

    VirtualMachine.without_callbacks do
      @vm = Factory(:setted_up_vm, :zone => @zone, :account => account)
    end

    @matrix = Factory(:matrix, :system_image => @vm.system_image, :zone => @zone)
    @zone.matrix_machines << @matrix
  end

  it "should select template and create machine" do
    @vm.should_receive(:select_template).ordered
    @vm.should_receive(:create_on_hypervisor).ordered
    @vm.clone_from_template
    @vm.status.should be(:machine_created)
  end

  it "should create machine on hypervisor" do
    template = "OpaqueRef:..."
    vm_clone = ["OpaqueRef:..."]
    vif_refs = ["OpaqRef:VIF"]
    vif_record = {"MAC" => "00:50:FF:FF:FF:FF"}
    vm_clone_record = {"uuid" => "5da854d7-7e5e-ce7b-7d12-50db55a12788"}
    old_params = {}
    new_params = {"weight" => @vm.priority.to_s}

    @hypervisor_session.VM.should_receive(:get_by_uuid).with(@vm.template_uuid).and_return(template)
    @hypervisor_session.VM.should_receive(:clone).with(template, @vm.name).and_return(vm_clone)
    MatrixMachine.should_receive(:find_by_system_image_id_and_zone_id).with(@vm.system_image, @vm.zone).and_return(@matrix)
    @hypervisor_session.VM.should_receive(:set_is_a_template).with(vm_clone, false)
    @hypervisor_session.VM.should_receive(:set_name_label).with(vm_clone, @vm.name)
    @hypervisor_session.VM.should_receive(:set_memory_dynamic_max).with(vm_clone, @vm.memory.megabyte.to_s)
    @hypervisor_session.VM.should_receive(:set_VCPUs_at_startup).with(vm_clone, @vm.cpus.to_s)
    @hypervisor_session.VM.should_receive(:set_VCPUs_max).with(vm_clone, @vm.cpus.to_s)
    @hypervisor_session.VM.should_receive(:get_VCPUs_params).with(vm_clone).and_return(old_params)
    @hypervisor_session.VM.should_receive(:set_VCPUs_params).with(vm_clone, new_params)
    @hypervisor_session.VM.should_receive(:get_record).with(vm_clone).and_return(vm_clone_record)
    @hypervisor_session.VM.should_receive(:get_VIFs).with(vm_clone).and_return(vif_refs)
    @hypervisor_session.VIF.should_receive(:get_record).with(vif_refs[0]).and_return(vif_record)
    @vm.create_on_hypervisor
    @vm.uuid.should be("5da854d7-7e5e-ce7b-7d12-50db55a12788")
    @vm.mac.should be("00:50:FF:FF:FF:FF")
  end



end

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe StateOperations do
  
  before :each do
    @hypervisor_session = mock_session
    HypervisorConnection.stub!(:hypervisor_session).and_return(@hypervisor_session)
    zone = Factory(:zone)
    zone.firewall = Factory(:firewall, :zone => zone)
    @vm = Factory(:installed_vm, :zone => zone)
  end
  
  it "should queue machine state change" do
    
    StateOperations::ACTION_STATE_MAP.each_pair do |key, value|
      StateManager.should_receive(:publish).with(:virtual_machine_id => @vm.id, :action => key)
      @vm.queue_state_change(key)
      @vm.reload.state.should be(value)
    end
  end
  
  it "should power on the machine" do
    vm_ref = "OpaqueRef:VM"
    start_paused = false
    force = false
    @hypervisor_session.VM.should_receive(:get_by_uuid).with(@vm.uuid).and_return(vm_ref)
    @hypervisor_session.VM.should_receive(:start).with(vm_ref, start_paused, force)

    @vm.power_on
    @vm.reload.state.should be(:ready)
  end
  
  it "should power off the machine" do
    vm_ref = "OpaqueRef:VM"
    @hypervisor_session.VM.should_receive(:get_by_uuid).with(@vm.uuid).and_return(vm_ref)
    @hypervisor_session.VM.should_receive(:clean_shutdown).with(vm_ref)

    @vm.power_off
    @vm.reload.state.should be(:ready)
  end
  
  it "should reboot the machine" do
    vm_ref = "OpaqueRef:VM"
    @hypervisor_session.VM.should_receive(:get_by_uuid).with(@vm.uuid).and_return(vm_ref)
    @hypervisor_session.VM.should_receive(:clean_reboot).with(vm_ref)

    @vm.reboot
    @vm.reload.state.should be(:ready)
  end
  
  it "should force vm shutdown" do
    @hypervisor_session.VM.should_receive(:get_by_uuid)
    @hypervisor_session.VM.should_receive(:get_record).and_return({})
    @hypervisor_session.VM.should_receive(:hard_shutdown)
    @vm.force_power_off
    
    @vm.reload.state.should be(:ready)
  end
  
  it "should force vm reboot" do
    @hypervisor_session.VM.should_receive(:get_by_uuid)
    @hypervisor_session.VM.should_receive(:hard_reboot)
    @vm.force_reboot
    @vm.reload.state.should be(:ready)
  end
  
end
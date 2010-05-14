require File.dirname(__FILE__) + '/../spec_helper'

describe CommonHypervisorOperations do
  
  before(:each) do
    @hypervisor_session = mock_session
    HypervisorConnection.stub!(:hypervisor_session).and_return(@hypervisor_session)
    zone = Factory(:zone)
    zone.firewall = Factory(:firewall, :zone => zone)
    @vm = Factory(:installed_vm, :zone => zone)
  end
  
  def vm_with_three_vbds_one_not_being_a_disk_type
    vm_record = ['OpaqueRef:...']

    vbd1 = {'type' => 'Disk', 'VDI' => 'OpaqueRef:vd1'}
    vbd2 = {'type' => 'CD', 'VDI' => 'OpaqueRef:vd2'}
    vbd3 = {'type' => 'Disk', 'VDI' => 'OpaqueRef:vdi3'}
    vbds = ['OpaqueRef:vbd1', 'OpaqueRef:vbd2', 'OpaqueRef:vbd3']

    [vm_record, vbd1, vbd2, vbd3, vbds]
  end
  
  it "should destroy the machine through XenAPI" do
    vm = "OpaqueRef:..."

    @hypervisor_session.VM.should_receive(:get_by_uuid).with(@vm.uuid).and_return(vm)
    @hypervisor_session.VM.should_receive(:destroy).with(vm).and_return(success_response)

    @vm.delete_machine
  end
  
  it "should remove all VDIs of type Disk" do

    vm, vbd1, vbd2, vbd3, vbds = vm_with_three_vbds_one_not_being_a_disk_type

    @hypervisor_session.VM.should_receive(:get_by_uuid).with(@vm.uuid).and_return(vm)
    @hypervisor_session.VM.should_receive(:get_VBDs).with(vm).and_return(vbds)
    @hypervisor_session.VBD.should_receive(:get_record).with(vbds[0]).and_return(vbd1)
    @hypervisor_session.VBD.should_receive(:get_record).with(vbds[1]).and_return(vbd2)
    @hypervisor_session.VBD.should_receive(:get_record).with(vbds[2]).and_return(vbd3)
    @hypervisor_session.VDI.should_receive(:destroy).with(vbd1['VDI']).and_return(success_response)
    @hypervisor_session.VDI.should_receive(:destroy).with(vbd3['VDI']).and_return(success_response)

    @vm.delete_disks
  end
end
require File.dirname(__FILE__) + '/../spec_helper'

describe Snapshot do
  
  before(:each) do
    @hypervisor_session = mock_session
    HypervisorConnection.stub!(:hypervisor_session).and_return(@hypervisor_session)
  end
  
  subject do
    zone = Factory(:zone)
    vm = Factory(:installed_vm, :zone => zone)
    Snapshot.create(:name => "snap", :virtual_machine => vm)
  end
  
  should_validate_presence_of :name, :virtual_machine
  should_belong_to :virtual_machine
  
  it "should create on hypervisor on database creation" do
    snapshot = Snapshot.new(:name => "snap", :virtual_machine => subject.virtual_machine)
    snapshot.should_receive(:queue_snapshot_creation).and_return(true)
    snapshot.save
  end
  
  it "should be pending" do
    snapshot = Snapshot.new
    snapshot.should be_pending
  end
  
  it "should not be pending" do
    snapshot = Snapshot.new :status => :done
    snapshot.should_not be_pending
  end
  
  it "should remove from hypervisor on database creation" do
    subject.should_receive(:remove_from_hypervisor).and_return(true)
    subject.destroy
  end
  
  it "should include common operation methods" do
    subject.should respond_to(:delete_disks)
    subject.should respond_to(:delete_machine)
  end
  
  it "should be removed from hypervisor" do
    subject.should_receive(:delete_disks).ordered
    subject.should_receive(:delete_machine).ordered
    subject.remove_from_hypervisor
  end
  
  it "should create a snapshot on hypervisor" do
    vm_ref = 'OpaqueRef:VM'
    snapshot_ref = 'OpaqueRef:VM_Snap1'
    subject.hypervisor_session.VM.should_receive(:get_by_uuid).with(subject.virtual_machine.uuid).and_return(vm_ref)
    subject.hypervisor_session.VM.should_receive(:snapshot).with(vm_ref, subject.name).and_return(snapshot_ref)
    subject.hypervisor_session.VM.should_receive(:get_record).with(snapshot_ref).and_return({"uuid" => "snap_uuid", "snapshot_time" => XMLRPC::DateTime.new(2010,2,3,4,5,6)})
    
    subject.create_on_hypervisor
    subject.uuid.should be("snap_uuid")
    subject.taken_at.should_not be_nil
  end

  it "should return the VM's zone" do
    vm = Factory.build(:installed_vm, :zone => Factory(:zone))
    subject.virtual_machine = vm
    subject.zone.should_not be_nil
    subject.zone.should be(vm.zone)
  end

  it "should queue the snapshot creation after create" do
    SnapshotManager.should_receive(:publish).with(:snapshot_id => subject.id, :action => "create")
    subject.save
    subject.status.should be(:creating)
  end

  it "should queue the snapshot removal" do
    Snapshot.without_callbacks do
      SnapshotManager.should_receive(:publish).with(:snapshot_id => subject.id, :action => "remove")
      subject.queue_snapshot_removal
      subject.status.should be(:removing)
    end
  end

  it "should queue the snapshot revertion" do
    Snapshot.without_callbacks do
      SnapshotManager.should_receive(:publish).with(:snapshot_id => subject.id, :action => "revert")
      subject.queue_snapshot_revertion
      subject.status.should be(:reverting)
    end
  end

  it "should revert the virtual machine to this snapshot" do
    subject.virtual_machine = VirtualMachine.new
    subject.virtual_machine.should_receive(:revert_to).with(subject)
    subject.revert
  end
end

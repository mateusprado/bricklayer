require File.dirname(__FILE__) + '/../spec_helper'

describe SnapshotManager do
  before :each do
    @snapshot = Snapshot.create! :name => "snap", :virtual_machine => Factory(:installed_vm)
    Snapshot.stub!(:find).and_return(@snapshot)
  end
  
  it "should create a new snapshot of the virtual machine" do
    processed_message_body = {:snapshot_id => @snapshot.id, :action => "create"}
    
    @snapshot.should_receive(:create_on_hypervisor)
    subject.send(:handle, processed_message_body)
    @snapshot.reload
    @snapshot.status.should be(:done)
  end
  
  it "should remove the snapshot" do
    processed_message_body = {:snapshot_id => @snapshot.id, :action => "remove"}
    
    @snapshot.should_receive(:remove_from_hypervisor)
    subject.send(:handle, processed_message_body)
  end
  
  it "should revert the snapshot" do
    processed_message_body = {:snapshot_id => @snapshot.id, :action => "revert"}
    
    @snapshot.should_receive(:revert)
    subject.send(:handle, processed_message_body)
    @snapshot.reload.status.should be(:done)
  end
  
  it "should log wrong actions" do
    processed_message_body = {:snapshot_id => @snapshot.id, :action => "lele"}
    logger = mock(:logger, :info => nil)
    subject.stub!(:logger).and_return logger
    
    logger.should_receive(:error)
    subject.send(:handle, processed_message_body)
    @snapshot.reload.status.should be(:done)
  end
   
end
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ProcessingError do
  it "should requeue the message for Consumer retrying" do
    message = {:virtual_machine_id => 1}
    TemplateCloner.should_receive(:publish).with(message)
    
    processing_error = ProcessingError.create!(:consumer => "TemplateCloner", :queue_message => message.to_yaml)
    processing_error.retry
    
    ProcessingError.all.should be_empty
  end
  
end
require File.dirname(__FILE__) + '/../spec_helper'

describe FirewallManager do
  before :each do
    @firewall_rule = FilterFirewallRule.create! :filter_port => 12345, :filter_protocol => "tcp", :virtual_machine => Factory(:installed_vm)
    FirewallRule.stub!(:find).and_return(@firewall_rule)
    FilterFirewallRule.stub!(:find).and_return(@firewall_rule)
  end
  
  it "should insert a new rule in the firewall" do
    processed_message_body = {:firewall_rule_id => @firewall_rule.id, :action => "insert"}
    
    @firewall_rule.should_receive(:insert)
    subject.send(:handle, processed_message_body)
    @firewall_rule.reload
    @firewall_rule.status.should be(:done)
  end
  
  it "should remove a rule from the firewall" do
    processed_message_body = {:firewall_rule_id => @firewall_rule.id, :action => "remove"}
    
    @firewall_rule.should_receive(:remove)
    subject.send(:handle, processed_message_body)
  end
  
  it "should log wrong actions" do
    processed_message_body = {:firewall_rule_id => @firewall_rule.id, :action => "lele"}
    logger = mock(:logger, :info => nil)
    subject.stub!(:logger).and_return logger
    
    logger.should_receive(:error)
    subject.send(:handle, processed_message_body)
    @firewall_rule.reload.status.should be(:done)
  end
  
end
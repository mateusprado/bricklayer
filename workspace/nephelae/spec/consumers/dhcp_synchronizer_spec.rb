require File.dirname(__FILE__) + '/../spec_helper'

describe DHCPSynchronizer do
	before(:each) do
		zone = Factory(:zone)
    @vm = Factory(:new_vm, :zone => zone, :name => "XXXCNN0001",
                  :mac => "00:00:00:00:00:00", :public_ip => Factory(:public_ip))
  	
  	@dhcp1 = Factory(:dhcp)
  	@dhcp2 = Factory(:dhcp, :ip => "10.11.0.12")
  end

  it "should be an exclusive consumer" do
    subject.class.exclusive?.should be_true
  end
  
  context "the consumer should be successful" do

	  it "if all dhcp machines were synchronized" do
	  	response = {:out => "STDOUT", :status => 0}
	  	
	  	@dhcp1.should_receive(:synchronize).and_return(response)
	  	@dhcp2.should_receive(:synchronize).and_return(response)
	  	DHCP.should_receive(:all).and_return([@dhcp1,@dhcp2])
	    subject.send(:handle, '')
	  end

		it "if at least one dhcp machine was synchronized" do
	  	@dhcp1.should_receive(:synchronize).and_return({:out => "STDOUT", :status => 0})
	  	@dhcp2.should_receive(:synchronize).and_return({:out => "STDOUT", :status => 1})
	  	DHCP.should_receive(:all).and_return([@dhcp1,@dhcp2])
	    subject.send(:handle, '')
	  end

  end
  
  it "should keep message if dhcp machines are off" do
  	response = {:out => "STDOUT", :status => 1}
  	
  	@dhcp1.should_receive(:synchronize).and_return(response)
  	@dhcp2.should_receive(:synchronize).and_return(response)
  	DHCP.should_receive(:all).and_return([@dhcp1,@dhcp2])
    lambda { subject.send(:handle, '') }.should raise_error(Exception)
  end

  context "when receiving an error from DCHP server" do
    before :each do
    	@dhcp1.should_receive(:synchronize).and_return(lambda{ raise 'DHCP server error' })
    	@dhcp2.should_receive(:synchronize).and_return({:out => "STDOUT", :status => 0})
    	DHCP.should_receive(:all).and_return([@dhcp1,@dhcp2])
    end

    it "should log it as a error" do
      subject.send(:logger).should_receive(:error)
      subject.send(:handle, '')
    end

    it "should not propagate the exception" do
      lambda { subject.send(:handle, '') }.should_not raise_error
    end
  end
end

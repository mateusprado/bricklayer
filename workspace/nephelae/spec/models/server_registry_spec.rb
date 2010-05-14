require File.dirname(__FILE__) + '/../spec_helper'

describe ServerRegistry do

  SERVER_REGISTRY_URL = NephelaeConfig[:server_registry]

  context "when creating a machine" do
    before :each do
      @vm = Factory(:new_vm)
      @machine_params = {
			 	:serverType => "GridServer",
				:managementType => "G0",
				:datacenter => "ITAPAIUNA",
				:operatingSystem => "centos",
				:parentServer => "HM852",
				:serviceType => "gridserver"
		  }

      @headers = subject.class::DEFAULT_HEADERS.merge({"Accept" => "application/vnd.locaweb.Server-1.0+xml"})
    end

    it "should work fine given the right paramaters and responses" do
      valid_response = HTTParty::Response.new('valid response', '<response>ok</response>', 200, 'valid response')
		  HTTParty.should_receive(:post).
        with("#{SERVER_REGISTRY_URL}/server", {:format=>:xml, :headers => @headers, :body => @machine_params, :parser => subject.class::XML_PARSER}).
        and_return(subject.class::XML_PARSER.call(valid_response.body, :xml))

      response = ServerRegistry.insert(@vm)
      response['response'].should == 'ok'
    end

    it "should not raise an error if the web service responds with an invalid body" do
      invalid_response = HTTParty::Response.new('invalid response', 'Invalid XML', 404, 'invalid response')
		  HTTParty.should_receive(:post).
        with("#{SERVER_REGISTRY_URL}/server", {:format=>:xml, :headers => @headers, :body => @machine_params, :parser => subject.class::XML_PARSER}).
        and_return(subject.class::XML_PARSER.call(invalid_response.body, :xml))

      response = ServerRegistry.insert(@vm)
      response.to_s.should include('XML parser error')
    end
  end

  it "should delete machine" do
    vm = VirtualMachine.new :name => "UNINSTALLED_VM"
    HTTParty.should_receive(:delete).
      with("#{SERVER_REGISTRY_URL}/server/UNINSTALLED_VM", {:headers => subject.class::DEFAULT_HEADERS})

    ServerRegistry.remove(vm)
  end

  it "should update mac" do
    vm = VirtualMachine.new :name => "TESTE", :mac => "00:11:22:33:44:55"
    machine_params = {:macAddress => vm.mac}

    HTTParty.should_receive(:put).
      with("#{SERVER_REGISTRY_URL}/server/#{vm.name}/eth0", {:headers => subject.class::DEFAULT_HEADERS, :body => machine_params})

    ServerRegistry.set_mac(vm)
  end

  it "should update server status" do
    vm = Factory.build(:new_vm)
    machine_params = {:status => 'IN_PRODUCTION'}
		HTTParty.should_receive(:put).
      with("#{SERVER_REGISTRY_URL}/server/#{vm.name}/status", {:headers => subject.class::DEFAULT_HEADERS, :body => machine_params})

    ServerRegistry.update_status(vm)
  end
end

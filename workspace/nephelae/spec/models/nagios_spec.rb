require File.dirname(__FILE__) + '/../spec_helper'

describe Nagios do

  context "when configuration is provided" do

    before(:each) do
      @vm = Factory.build(:new_vm, :name => "VM", :public_ip => Factory(:public_ip))
    
      wsdl = Object.new
      @proxy = Object.new
    
      SOAP::WSDLDriverFactory.should_receive(:new).with(NephelaeConfig[:nagios_wsdl]).and_return(wsdl)
      wsdl.should_receive(:create_rpc_driver).and_return(@proxy)
    end
  
    it "should insert vm for monitoring" do
      @proxy.should_receive(:host).with(@vm.name, @vm.name, @vm.public_ip).and_return("Servidor Inserido")
    
      Nagios.insert(@vm)
    end
  
    it "should raise error if ain't able to insert vm" do
      response = "Msg generica"
      @proxy.should_receive(:host).with(@vm.name, @vm.name, @vm.public_ip).and_return(response)
    
      lambda{Nagios.insert(@vm)}.should raise_error("Wrong Nagios response: #{response}")
    end
  
    it "should remove vm from monitoring" do
      @proxy.should_receive(:monitor).with(@vm.name, 3).and_return("Servidor Excluido")
    
      Nagios.remove(@vm)
    end
  
    it "should raise error if ain't able to remove vm" do
      response = "Msg generica"
      @proxy.should_receive(:monitor).with(@vm.name, 3).and_return(response)
    
      lambda{Nagios.remove(@vm)}.should raise_error("Wrong Nagios response: #{response}")
    end
    
  end
  
  context "when no configuration is provided" do
    
    before(:each) do
      NephelaeConfig.should_receive(:[]).with(:nagios_wsdl).and_return nil
    end
    
    it "should ignore insertion and log a warning" do
      vm = mock("virtual machine")
      Rails.logger.should_receive(:warn).with("*****PLEASE CHECK***** Nagios config is missing. Ignoring monitoring for now.")
      Nagios.insert(vm)
    end

    it "should ignore removal and log a warning" do
      vm = mock("virtual machine")
      Rails.logger.should_receive(:warn).with("*****PLEASE CHECK***** Nagios config is missing. Ignoring monitoring for now.")
      Nagios.remove(vm)
    end
    
  end

end

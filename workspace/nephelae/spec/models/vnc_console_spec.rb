require 'spec_helper'

describe VncConsole do
  should_belong_to :virtual_machine, :vnc_proxy
  should_validate_presence_of :virtual_machine, :vnc_proxy
  should_validate_numericality_of :port, :only_integer => true, :greater_than_or_equal_to => 5900, :less_than_or_equal_to => 65535
  
  before :each do
    @vnc_proxy = Factory(:vnc_proxy)
    @vm = Factory(:installed_vm)
  end

  subject { VncConsole.new :virtual_machine => @vm, :vnc_proxy => @vnc_proxy }

  it "should generate a new password when an instance is created" do
    subject.password.should_not be_blank
  end

  it "should get free port assigned when a new instance is created" do
    subject.port.should_not be_blank
  end

  it "should be valid once it's assined a vm and a VNC Proxy" do
    subject.should be_valid
  end

  it "should increment the port when a record already exists" do
    subject.save
    other_vm = Factory(:installed_vm)
    other_vnc = VncConsole.create! :virtual_machine => other_vm, :vnc_proxy => @vnc_proxy
    other_vnc.port.should be(subject.port + 1)
    @vm.console.port.should be(subject.port)
  end
end

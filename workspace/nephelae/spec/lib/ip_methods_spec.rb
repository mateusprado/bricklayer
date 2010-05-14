require File.dirname(__FILE__) + "/../spec_helper"

describe IpMethods do
  class HostIP
    include IpMethods
    attr_accessor :address, :mask
    
    def initialize(address, mask)
      @address = address
      @mask = mask
    end
  end
  
  subject { HostIP.new "10.1.2.34", 27 }
  
  it "should give the binary ip representation" do
    subject.to_bin.should be(0b00001010_00000001_00000010_00100010)
  end
  
  it "should convert from binary ip representation" do
    IpMethods.from_bin(subject.to_bin).should be(subject.address)
  end
  
  it "should give the ip's network address" do
    subject.network.should be("10.1.2.32")
  end
  
  it "should give the ip's broadcast address" do
    subject.broadcast.should be("10.1.2.63")
  end
  
  it "should give the ip's default gateway address" do
    subject.default_gateway.should be("10.1.2.33")
  end
  
  it "should give the ip's net mask address" do
    subject.net_mask.should be("255.255.255.224")
  end
  
  it "should generate all host ips on this ip range" do
    ips = []
    ip = subject.network
    30.times {ips << ip = ip.next}
    subject.generate_ips.should be(ips)
  end
end
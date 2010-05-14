require File.dirname(__FILE__) + '/../spec_helper'

describe VncProxySynchronizer do
  it "should be assigned to vnc proxy queue" do
    subject.queue_name.should =~ /VncProxy$/
  end

  it "should be an exclusive consumer" do
    subject.class.exclusive?.should be_true
  end

  it "it should call synchronize for all vnc proxies" do
    zone = Factory(:zone)
    proxy_1 = Factory(:vnc_proxy, :zone => zone)
    proxy_2 = Factory(:vnc_proxy, :zone => zone)
    
    subject.should_receive(:build_xvp_configuration).with(proxy_1).and_return(:proxy_1_configuration)
    subject.should_receive(:build_xvp_configuration).with(proxy_2).and_return(:proxy_2_configuration)
    proxy_1.should_receive(:synchronize).with(:proxy_1_configuration)
    proxy_2.should_receive(:synchronize).with(:proxy_2_configuration)

    VncProxy.should_receive(:all).and_return([proxy_1, proxy_2])

    lambda{ subject.send(:handle, nil) }.should_not raise_error
  end

  it "should render the synchronization script for the proxy" do
    proxy = VncProxy.new(:address => '192.168.0.1')
    subject.send(:build_xvp_configuration, proxy).should be("OK 192.168.0.1\n")
  end
end

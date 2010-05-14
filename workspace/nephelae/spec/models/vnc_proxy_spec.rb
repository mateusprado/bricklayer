require 'spec_helper'

describe VncProxy do
  should_belong_to :zone
  should_have_many :vnc_consoles
  should_validate_presence_of :address, :zone
  
  context 'when synchronizing' do
    before :each do
      @fake_ssh = mock(:ssh)
      fake_address = '10.0.0.1'
      SSHExecutor.should_receive(:new).with(fake_address, 'root').and_return(@fake_ssh)
      subject.address = fake_address
    end

    it 'should not raise an error when operation return a status equal to zero' do
      @fake_ssh.should_receive(:exec).with(:synchronize_xvp, {:xvp_config => :some_config}).and_return(:status => 0)
      lambda {subject.synchronize(:some_config)}.should_not raise_error
    end

    it 'should raise an error if operation returns a status different from zero' do
      @fake_ssh.should_receive(:exec).with(:synchronize_xvp, {:xvp_config => :some_config}).and_return(:status => 1)
      lambda {subject.synchronize(:some_config)}.should raise_error
    end
  end

  it 'should have the encrypted_root_password' do
    subject.zone = Zone.new(:hosts => [Host.new(:password => 'Secret!')])
    subject.encrypted_root_password.should be('Secret!')
  end
  
  it 'should return the last port used' do
    subject.port.should be(5900)
  end
  
  it 'should return the next port available' do
    last_port = subject.port
    new_port = subject.port + 1
    subject.port += 1
    subject.save
    new_port.should be(last_port + 1)
    subject.port.should be(new_port)
  end
  
end

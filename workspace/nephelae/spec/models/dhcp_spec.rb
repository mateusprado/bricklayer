require File.dirname(__FILE__) + '/../spec_helper'

describe DHCP do

  it "should insert machine" do
		@zone = Factory(:zone)
    @centos = Factory(:centos)
    @vm = Factory(:new_vm, :zone => @zone, :system_image => @centos, :name => "XXXCNN0001", :mac => "00:00:00:00:00:00", :public_ip => Factory(:public_ip))

    @ssh_executor = mock("SSHExecutor")
    
    @dhcp = Factory(:dhcp)

    response = {:out => "STDOUT", :status => 0}
    
    SSHExecutor.should_receive(:new).with(@dhcp.ip, @dhcp.username).and_return(@ssh_executor)
    @ssh_executor.should_receive(:exec).with(:synchronize_dhcp, {:dhcp_config => mock_dhcp_config}).and_return(response)
      
    @dhcp.synchronize(mock_dhcp_config)
  end
  
  def mock_dhcp_config
  	"# <%= @vm.name %>
		 host <%= @vm.name %> {
		 	hardware ethernet <%= @vm.mac %>;
			fixed-address <%= @vm.public_ip %>;
			option host-name \"<%= @vm.name %>\";
		 }"
  end

end

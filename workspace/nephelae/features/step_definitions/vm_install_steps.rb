Given /^an existent account$/ do
  @account = Factory(:test_account)
end

Given /^an existent zone$/ do
  @zone = Factory(:zone)
end

Given /^an existent vlan$/ do
  vlan_number = rand(900) + 1100
  @vlan = Factory(:vlan, :zone => @zone, :number => vlan_number)
end

Given /^an existent master$/ do
  @master = Factory(:master, :zone => @zone)
end

Given /^an existent public_ip range$/ do
  @ip_range = Factory(:ip_range)
end

Given /^an existent "([^\"]*)" matrix with uuid "([^\"]*)"$/ do |system_image, uuid|
  @system_image = Factory(system_image.to_sym)
  matrix = Factory(:matrix, :system_image => @system_image, :uuid => uuid, :template_uuid => nil, :zone => @zone)
end

Given /^an existent DHCP server$/ do
  Factory(:dhcp)
end

Given /^an existent Firewall$/ do
  Factory(:firewall, :zone => @zone)
end

Given /^an existent VncProxy/ do
  Factory(:vnc_proxy, :zone => @zone)
end

Given /^a virtual machine$/ do
  @vm = VirtualMachine.new(:memory => 1024, :hdd => 10, :cpus => 1, :system_image => @system_image, :account => @account, :zone => @zone)
end

When /^I set password as "([^\"]*)"$/ do |password|
  @vm.password = password
  @vm.password_confirmation = password
  @password = password
end

When /^I save$/ do 
  @vm.save!
  @vm.id.should_not be_nil
end

Then /^it should change state to "([^\"]*)" after (\d+) minutes$/ do |state, timeout|
  Timeout::timeout timeout.to_i.minutes.to_i do
    loop do 
      break if @vm.reload.status.to_s == state
      sleep 10
    end
  end
end

Then /^it should have valid public and private ip address$/ do
  @vm.public_ip.should_not be_nil
  @vm.private_ip.should_not be_nil
end

Then /^it should be accessible using ssh with user and password$/ do
  ssh = SSHExecutor.new @vm.public_ip.address, "root", @password
  ssh.exec(:uname)[:status].should be(0)
end

Then /^it should not be accessible using ssh with keys$/ do
  ssh = SSHExecutor.new @vm.public_ip.address, "root"
  lambda{ssh.exec(:uname)}.should raise_error
end

Then /^the security sensitive files should be deleted$/ do
  ssh = SSHExecutor.new @vm.public_ip.address, "root", @password
  ssh.exec(:check_security_sensitive_files)[:status].should be(0)
end

Then /^it should be in production network$/ do
  production_network_ref = @vm.hypervisor_session.network.get_by_name_label(NephelaeConfig[:production_network])[0]
  vm_ref = @vm.hypervisor_session.VM.get_by_uuid(self.uuid)
  vif_ref = @vm.hypervisor_session.VM.get_VIFs(vm_ref)[0]
  vif_record = hypervisor_session.VIF.get_record(vif_ref)
  vif_record["network"].should be(production_network_ref)
end

Then /^it should be able to access internet$/ do
  ssh = SSHExecutor.new @vm.public_ip.address, "root", @password
  ssh.exec(:test_internet_access)[:status].should be(0)
end

Then /^it should have the defined hardware$/ do
  vm_ref = @vm.hypervisor_session.VM.get_by_uuid(@vm.uuid)
  vm_details = @vm.hypervisor_session.VM.get_record(vm_ref)
  memory = vm_details['memory_dynamic_max'].to_i
  cpus = vm_details['VCPUs_max'].to_i
  vdi_ref = @vm.hypervisor_session.VBD.get_record(vm_details['VBD'][1])['VDI']
  disk = @vm.hypervisor_session.VDI.get_record(vdi_ref)['virtual_size'].to_i

  memory.should be(@vm.memory.megabytes)
  cpus.should be(@vm.cpus)
  disk.should be(@vm.hdd.gigabytes)
end

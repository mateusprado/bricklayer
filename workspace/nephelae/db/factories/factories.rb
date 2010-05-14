Factory.define :zone do |p|
  p.name "ITAPAIUNA"
  p.priority 1
  p.number 1
end

Factory.define :low_priority_zone, :class => Zone do |p|
  p.name "JK"
  p.priority 2
end

Factory.define :host do |h|
  h.ip "10.9.19.221"
  h.name "XEN06"
  h.username "root"
  h.password "locadmin123!@#"
  h.after_build {|h| h.zone ||= Factory(:zone)}
end

Factory.define :master, :parent => :host do |h|
  h.ip "10.9.19.220"
  h.name "XEN05"
  h.master true
end

Factory.define :matrix, :class => MatrixMachine do |m|
	m.name "Matrix"
	m.uuid "matrix_uuid"
  m.template_uuid "template_uuid"
  m.template_copies 19
end

Factory.define :win_matrix, :class => MatrixMachine do |m|
	m.name "MATRIX_WINDOWS_2003"
	m.uuid "win_matrix_uuid"
  m.template_uuid "win_template_uuid"
  m.template_copies 19
end

Factory.define :centos, :class => SystemImage do |f|
  f.code "centos"
  f.name "CentOS 5.3 i386"
  f.minimum_cpus 1
  f.minimum_hdd 1
  f.minimum_memory 512
  f.architecture 32
end

Factory.define :centos_64, :class => SystemImage do |f|
  f.code "centos"
  f.name "CentOS 5.3 x64"
  f.minimum_cpus 1
  f.minimum_hdd 1
  f.minimum_memory 512
  f.architecture 64
end

Factory.define :debian, :class => SystemImage do |f|
  f.code "debian"
  f.name "Debian 5.0.3 i386"
  f.minimum_cpus 1
  f.minimum_hdd 1
  f.minimum_memory 512
  f.architecture 32
end

Factory.define :debian_64, :class => SystemImage do |f|
  f.code "debian"
  f.name "Debian 5.0.4 x64"
  f.minimum_cpus 1
  f.minimum_hdd 1
  f.minimum_memory 512
  f.architecture 64
end

Factory.define :red_hat, :class => SystemImage do |f|
  f.code "redhat"
  f.name "Red Hat Enterprise Linux 5.3"
  f.minimum_cpus 1
  f.minimum_hdd 1
  f.minimum_memory 512
  f.architecture 32
end

Factory.define :red_hat_64, :class => SystemImage do |f|
  f.code "redhat"
  f.name "Red Hat Enterprise Linux 5.3 x64"
  f.minimum_cpus 1
  f.minimum_hdd 1
  f.minimum_memory 512
  f.architecture 64
end

Factory.define :win_2k3, :class => SystemImage do |f|
  f.code "windows"
  f.name "Windows 2003 Server Enterprise Edition"
  f.minimum_cpus 1
  f.minimum_hdd 1
  f.minimum_memory 1024
  f.architecture 32
end

Factory.define :win_2k3_64, :class => SystemImage do |f|
  f.code "windows"
  f.name "Windows 2003 Server Enterprise Edition x64"
  f.minimum_cpus 1
  f.minimum_hdd 1
  f.minimum_memory 1024
  f.architecture 64
end

Factory.define :win_2k8, :class => SystemImage do |f|
  f.code "windows"
  f.name "Windows 2008 Server Enterprise Edition"
  f.minimum_cpus 1
  f.minimum_hdd 1
  f.minimum_memory 1024
  f.architecture 32
end

Factory.define :win_2k8_64, :class => SystemImage do |f|
  f.code "windows"
  f.name "Windows 2008 Server Enterprise Edition x64"
  f.minimum_cpus 1
  f.minimum_hdd 1
  f.minimum_memory 1024
  f.architecture 64
end

Factory.define :system_image_with_minimum_configuration, :class => SystemImage do |f|
	f.code "redhat"
	f.name "VM WITH MINIMUM CONFIG"
  f.minimum_cpus 2
  f.minimum_hdd 20
  f.minimum_memory 2048
  f.architecture 32
end

Factory.define :limited_account, :class => Account do |account|
  account.login 'limited account'
  account.maximum_machine_count 1
  account.maximum_memory 4096
  account.maximum_hdd 80
  account.maximum_cpus 4
end

Factory.define :unlimited_account, :class => Account do |account|
  account.login 'unlimited account'
  account.maximum_machine_count 100
  account.maximum_memory 100000000
  account.maximum_hdd 100000
  account.maximum_cpus 1000
end

Factory.define :test_account, :parent => :unlimited_account do |account|
  account.login "zteste99/zteste99"
end

Factory.define :client_account, :parent => :unlimited_account do |account|
  account.login "client"
end

Factory.define :valid_vm, :class => VirtualMachine do |vm|
  vm.name "CLOUD_1"
  vm.memory 512
  vm.hdd 50
  vm.cpus 2
  vm.password "$P4ssw0rd^"
  vm.after_build do |vm|
    vm.public_uuid ||= vm.send(:generate_public_uuid)
    vm.system_image ||= Factory(:centos)
    vm.account ||= Factory(:client_account)
  end
end

Factory.define :setted_up_vm, :parent => :valid_vm do |vm|
  vm.status :not_created
end

Factory.define :new_vm, :parent => :valid_vm do |vm|
  vm.status :machine_created
end

Factory.define :installed_vm, :parent => :valid_vm do |vm|
	vm.status :installed
	vm.uuid "installed_vm_uuid"
	vm.name "INSTALLED_VM"
end

Factory.define :uninstalled_vm, :parent => :valid_vm do |vm|
	vm.status :uninstalled
	vm.uuid "uninstalled_vm_uuid"
	vm.name "UNINSTALLED_VM"
	vm.mac "00:00:00:00:00:01"
end

Factory.define :awaiting_validation_vm, :parent => :valid_vm do |vm|
	vm.status :awaiting_validation
end

Factory.define :dhcp, :class => DHCP do |dhcp|
	dhcp.ip "200.234.206.152"
	dhcp.username "sservice"
end

Factory.define :public_ip, :class => Ip do |ip|
  ip.address "10.11.2.3"
  ip.after_build {|ip| ip.ip_range ||= Factory(:ip_range) }
end

Factory.define :ip_range, :class => IpRange do |range|
  range.address "10.11.0.0"
  range.mask 24
end

Factory.define :vlan, :class => Vlan do |vlan|
	vlan.number 1501
  vlan.after_build {|vlan| vlan.zone ||= Factory(:zone) }
end

Factory.define :firewall do |fw|
  fw.ip_address "200.234.206.152"
  fw.after_build {|fw| fw.zone ||= Factory(:zone)}
end

Factory.define :filter_firewall_rule, :class => FilterFirewallRule do |rule|
  rule.description 'SSH'
  rule.filter_protocol :tcp
  rule.filter_port 22
  rule.filter_address '0.0.0.0'
end

Factory.define :nat_firewall_rule, :class => NatFirewallRule do |rule|
end

Factory.define :vnc_proxy, :class => VncProxy do |vnc_proxy|
  vnc_proxy.address "10.9.19.222" 
  vnc_proxy.after_build {|vp| vp.zone ||= Factory(:zone)} 
end

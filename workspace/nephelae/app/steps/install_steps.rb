module InstallSteps

  def set_network_to_production
  	log_activity(:debug, "Setting network to production")

    vm_ref = hypervisor_session.VM.get_by_uuid(self.uuid)
    vif_refs = hypervisor_session.VM.get_VIFs(vm_ref)
		
		log_activity do
	    raise "The machine #{uuid.inspect} didn't return network interfaces." if vif_refs.nil? || vif_refs.empty?
	  end

    old_vif_ref = vif_refs[0]
    old_vif_record = hypervisor_session.VIF.get_record(old_vif_ref)
    vif_record = old_vif_record

    production_network_ref = hypervisor_session.network.get_by_name_label(self.production_network)
		
		log_activity do
    	raise "The production network #{production_network.inspect} wasn't returned by the API." if production_network_ref.nil? || production_network_ref.empty?
    end

    vif_record["network"] = production_network_ref[0]

		log_activity(:debug, "Destroying previous vif")
    hypervisor_session.VIF.destroy(old_vif_ref)

		log_activity(:debug, "Creating vif")
    new_vif = hypervisor_session.VIF.create(vif_record)
    log_activity(:info, "VIF created");
  end

  def set_network_rate_limit
  	log_activity(:debug, "Setting network rate limit")
    vm_ref = hypervisor_session.VM.get_by_uuid(self.uuid)
    vif_refs = hypervisor_session.VM.get_VIFs(vm_ref)
    hypervisor_session.VIF.set_qos_algorithm_params(vif_refs[0], {'kbps' => self.rate_limit})
    log_activity(:info, "Rate limit done")
  end

  def add_data_disk
  	log_activity(:debug, "Adding data disk")
    storage = self.zone.define_storage_to_data_disk_of(self)
    storage.create_data_disk_for(self)
    log_activity(:info, "Data disk done")
  end

  def create_nat_rule
  	log_activity(:debug, "Creating Nat Firewall rule")
    NatFirewallRule.create! :virtual_machine => self
  end

  def create_default_filter_rules
  	log_activity(:debug, "Creating Filter Firewall rule")
    NephelaeConfig[:opened_ports].each do |port|
      FilterFirewallRule.create! :virtual_machine => self, :filter_port => port, :filter_protocol => :tcp
    end
  end

  def create_vnc_console
  	log_activity(:debug, "Creating console")
    VncConsole.create! :virtual_machine => self, :vnc_proxy => self.zone.vnc_proxy
  end

  def wait_ssh_start_up
  	log_activity(:debug, "Waiting #{NephelaeConfig[:vm_ssh_wait_time]}s, then will start trying to connect to vm #{uuid} for #{NephelaeConfig[:vm_startup_time]} seconds")
    sleep NephelaeConfig[:vm_ssh_wait_time]
    ssh = SSHExecutor.new(self.public_ip.address, 'root')
    Timeout::timeout(NephelaeConfig[:vm_startup_time]) do
      while true
        begin
        	log_activity(:debug, "Attempting to connect to vm #{uuid}, ip: #{public_ip.address}")
          result = ssh.exec :ssh_check
          log_activity(:info, "Connected to vm #{uuid}, ip: #{public_ip.address}. Result #{result[:out]}")
          break
        rescue => error
        	log_activity(:info,"Could not connect to the vm #{uuid}, ip: #{public_ip.address}. Trying again in 5s. Error: #{error}")
        	log_activity(:error, error)
          sleep 5
        end
      end
    end
  end

  def change_password
  	log_activity(:debug, "POSINSTALL: Changing password for machine #{self.uuid}")
    ssh = SSHExecutor.new(self.public_ip.address, 'root')
    new_password_hash = hash_password
    log_activity(:info, "POSINSTALL: The new password hash is going to be: #{new_password_hash}")
    result = ssh.exec(:change_passwd, {:passwd_hash => new_password_hash})
    log_activity(:info, "Password script executed. The output was: #{result[:out]}")
    if result[:status] == 0
      self.password = ''
      self.save
    else
    	log_activity do
      	raise "Error while attempting to change password: #{result[:out]}"
      end
    end
  end

  def clean_template_files
  	log_activity(:debug, "POSINSTALL: Cleaning template of machine #{self.uuid}")
    ssh = SSHExecutor.new(self.public_ip.address, 'root')
    result = ssh.exec :clean_template_files
    log_activity do
    	raise "Error while attempting to delete template files: #{result[:out]}" unless result[:status] == 0
    end
  end

  def notify_install
    insert_on_nagios
  end

  private
    def confirm_installation_to_server_registry
      response = ServerRegistry.update_status(self)
      log_activity do
	      raise("Fail to set status. Server Registry returned: #{response.inspect}") unless response.code.to_s =~ /2\d\d/
	    end
    end

    def salt
      salt = ""
      seeds = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a + ['/', '.']
      8.times { salt << seeds[ rand seeds.size ] }
      salt
    end

    def hash_password
      # FIXME Sampaio: stress test que garante que várias senhas não quebram
      log_activity do
	      raise "Virtual Machine doesn't have a assigned password" if password.blank?
	    end
      hash = Open3.popen3("openssl", "passwd" , "-1", "-salt", salt, password) do |stdin, stdout, stderr|
        stdout.read
      end
      hash.chomp!
      hash.gsub!(/\$/, '\$')
      hash.gsub!(/\./, '\.')
      hash.gsub!(/\//, '\/')
      hash
    end

    def insert_on_nagios
      Nagios.insert(self)
    end

end

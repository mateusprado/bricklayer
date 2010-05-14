module SetupInstallationSteps
  
  def validate_zone_availability
    log_activity(:debug, "Validating zone availability")
        
    log_activity do
       raise "Zone #{self.zone} not available" unless zone.can_accomodate_machine?(self)
    end
    log_activity(:info, "Zone #{self.zone} available for installation")
  end

  def select_name
    log_activity(:debug, "Selecting name")
    
    self.name = "CLOUD_#{self.id}"
    log_activity(:info, "Name selected: #{self.name}")
  end

  def select_public_ip
    log_activity(:debug, "Selecting public ip")
    
    self.public_ip = Ip.find_free_public_ip 
    log_activity do
       raise "Could not find public ip" if public_ip.nil?
    end
    log_activity(:info, "Got public ip: #{self.public_ip.address}")
  end

  def select_private_ip
    log_activity(:debug, "Selecting private ip")
    
    #FIXME: vlan association not needed on virtual machine
    self.vlan = Vlan.find_for(self)
    log_activity do
       raise "Could not find vlan" if vlan.nil?
    end
    
    self.private_ip = Ip.find_free_private_ip(vlan)
    log_activity do
       raise "Could not find private ip" if private_ip.nil?
    end
    
    log_activity(:info, "got private ip: #{self.private_ip.address}")
  end
end


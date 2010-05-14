module UninstallSteps
  
  def release_ips
    self.public_ip = nil
    self.private_ip = nil
  end
  
  def release_zone
    self.zone = nil
  end
  
  def delete_firewall_rules
    self.firewall_rules.destroy_all
  end
  
  def clean_filter_chain
    logger.info "Trying to clean filter chain: #{self.private_ip}/32"
    ssh_executor = SSHExecutor.new(self.firewall.ip_address, 'sservice')
    result = ssh_executor.exec(:clean_filter_chain, {:vm => self})
    raise "Could not clean filter chain: #{result[:out]}" unless result[:status] == 0
    logger.info "Cleaned filter chain: #{self.private_ip}/32"
  end
  
  def notify_uninstall
    remove_from_nagios
  end
  
  private
    def remove_from_nagios
      Nagios.remove(self)
    end
  
end

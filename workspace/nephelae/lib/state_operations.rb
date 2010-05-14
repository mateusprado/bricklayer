module StateOperations
  
  ACTION_STATE_MAP = {:force_shutdown => :shutting_down, :shutdown => :shutting_down,
                      :start => :starting, :reboot => :rebooting, :force_reboot => :rebooting}
  
  STATES = ACTION_STATE_MAP.values + [:reverting, :ready]
  
  def queue_state_change(action)
    update_attribute(:state, ACTION_STATE_MAP[action.to_sym]) if action != "uninstall"
    StateManager.publish(:virtual_machine_id => id, :action => action)
  end
  
  def force_power_off
    logger.info "Forcing power off of vm #{self.uuid}"
    vm_ref = hypervisor_session.VM.get_by_uuid(self.uuid)
    vm_record = hypervisor_session.VM.get_record(vm_ref)
    hypervisor_session.VM.hard_shutdown(vm_ref) if vm_record["power_state"] != "Halted"
  ensure
    update_attribute(:state, :ready)
  end
  
  def force_reboot
    logger.info "Forcing reboot of vm #{self.id}"
    vm_ref = hypervisor_session.VM.get_by_uuid(self.uuid)
    hypervisor_session.VM.hard_reboot(vm_ref)
  ensure
    update_attribute(:state, :ready)
  end
  
  def reboot
    logger.info "Rebooting vm #{self.id}"
    vm_ref = hypervisor_session.VM.get_by_uuid(self.uuid)
    hypervisor_session.VM.clean_reboot(vm_ref)  
  ensure
    update_attribute(:state, :ready)
  end
  
  def power_on
    logger.info "Powering on vm #{self.id}"
    vm_ref = hypervisor_session.VM.get_by_uuid(self.uuid)
    start_paused = false
    force = false
    hypervisor_session.VM.start(vm_ref, start_paused, force)
  ensure
    update_attribute(:state, :ready)
  end
  
  def power_off
    logger.info "Powering off vm #{self.id}"
    vm_ref = hypervisor_session.VM.get_by_uuid(self.uuid)
    hypervisor_session.VM.clean_shutdown(vm_ref)
  ensure
    update_attribute(:state, :ready)
  end

  def revert_to(snapshot)
    logger.info "Reverting vm #{self.id} to snapshot #{snapshot.id}"
    force_power_off
    use_cloned_disks_from(snapshot)
    power_on
  end
end

module CommonHypervisorOperations
  def delete_disks
    vm = hypervisor_session.VM.get_by_uuid(self.uuid)
    vbds = hypervisor_session.VM.get_VBDs(vm)
    vbds.each do |vbd|
      record = hypervisor_session.VBD.get_record(vbd)
      
      if record['type'] == 'Disk'
        response = hypervisor_session.VDI.destroy(record['VDI'])
        logger.info "Disk removal response: #{response.inspect}"
      end
    end
  end
  
  def delete_machine
    vm = hypervisor_session.VM.get_by_uuid(self.uuid)
    response = hypervisor_session.VM.destroy(vm)
    logger.info "Machine removal response: #{response.inspect}"
  end
end
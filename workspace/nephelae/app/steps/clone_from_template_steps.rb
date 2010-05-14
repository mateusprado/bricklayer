module CloneFromTemplateSteps
  def select_template
    log_activity(:debug, "Selecting template for virtual machine")
    begin
      self.template_uuid = self.zone.define_template_uuid_for(self.system_image)
    rescue Exception => e
      log_activity(:error, e)  
    end
  end
  
  def create_on_hypervisor
    begin
      log_activity(:debug, "Creating virtual machine on hypervisor")
      log_activity(:debug, "Searching template by uuid")
      
      template_machine = hypervisor_session.VM.get_by_uuid(template_uuid)
      vm_clone = hypervisor_session.VM.clone(template_machine, name)

      log_activity(:debug, "Searching for matrix machine")
      matrix = MatrixMachine.find_by_system_image_id_and_zone_id(self.system_image, self.zone)
      matrix.template_copies += 1
      matrix.save
      
      log_activity(:debug, "Setting up the clone vm")
      hypervisor_session.VM.set_name_label(vm_clone, self.name)
      hypervisor_session.VM.set_is_a_template(vm_clone, false)
      hypervisor_session.VM.set_memory_dynamic_max(vm_clone, self.memory.megabyte.to_s)
      hypervisor_session.VM.set_VCPUs_at_startup(vm_clone, self.cpus.to_s)
      hypervisor_session.VM.set_VCPUs_max(vm_clone, self.cpus.to_s)
      
      log_activity(:debug, "Setting up priority")
      parameters = hypervisor_session.VM.get_VCPUs_params(vm_clone)
      parameters["weight"] = self.priority.to_s
      hypervisor_session.VM.set_VCPUs_params(vm_clone, parameters)
      
      log_activity(:debug, "Setting up network interfaces")
      vif_refs = hypervisor_session.VM.get_VIFs(vm_clone)
      vif_ref = vif_refs[0]
      vif_record = hypervisor_session.VIF.get_record(vif_ref)
      
      self.uuid = hypervisor_session.VM.get_record(vm_clone)["uuid"]
      self.mac = vif_record["MAC"]
      
      log_activity(:info, "Virtual machine created on hypervisor")
    rescue Exception => e
      log_activity(:error, e)
    end
  end
end

ProcessSpecification.after_processes do |process_object|
  HypervisorConnection.close_hypervisor_session!
end

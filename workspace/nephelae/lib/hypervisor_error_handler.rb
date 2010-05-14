require 'timeout'

class HypervisorErrorHandler
	attr_accessor :zone, :error
	
	TIMEOUT = 30
	
	def initialize(zone, error)
		self.zone = zone
		self.error = error
	end
	
	def handle_error
	  logger.debug "Handling error on Hypervisor Connection: #{error.class} #{error}"
		if self.error.is_a? XenAPI::AuthenticationError
			send_critical_warning_for self.error
		elsif self.error.is_a? XenAPI::ExpirationError #EOFError
			reconnect_to_master
		elsif self.error.is_a? XenAPI::TimeoutError
			reconnect_to_master
		elsif self.error.is_a? XenAPI::NotMasterError
			connect_to_real_master_at self.error.master_ip
		elsif self.error.is_a? XenAPI::ConnectionError
			check_first_slave_and_connect
		else
			raise self.error
		end
		
	end
	
	private
	def reconnect_to_master
		begin
		  master = zone.reload.master!
		  logger.debug "Reconnecting to master #{master.name}"
		  connect_to master
		rescue Exception => exc
		  logger.debug "Reconnect to master #{master.name} failed"
		  check_first_slave_and_connect
	  end
	end
	
	def connect_to_real_master_at(master_ip)
		begin
		  logger.debug "Connecting to real master at #{master_ip}"
		  real_master = zone.hosts.find_by_ip(master_ip)
		  raise "Host not on DB: #{master_ip}" unless real_master
		  
		  connect_to real_master
		rescue Exception => exc
  		logger.debug "Connection to real master failed"
		  send_critical_warning_for exc
	  end
	end
	
	def check_first_slave_and_connect
		slaves = [] << zone.reload.hosts.find_by_master(false)
		slave = slaves.first
		
		logger.debug "Trying slave: #{slave.name}"
		
		begin
			connect_to slave
		# If master is down is should timeout
		rescue XenAPI::TimeoutError
			make_it_master_and_connect(slave)
		# TODO: RECURSION RISK?
		rescue XenAPI::NotMasterError => err
			connect_to_real_master_at err.master_ip
		rescue Exception => exc
		  send_critical_warning_for exc
		end
	end
	
	def make_it_master_and_connect(slave)
	  begin
		  logger.debug "Making slave #{slave.name} the new master"
  		change_to_master_on_hypervisor(slave)
  		
  		connect_to slave
		rescue Exception => exc
		  send_critical_warning_for exc
	  end
	end
	
	def change_to_master_on_db(new_master)
		zone.transaction do
		  zone.reload.hosts.each do |host|
	      host.master = false
	      host.save!
	    end
			new_master.reload.master = true
			new_master.save!
		end
		zone.reload.master!
	end

	def change_to_master_on_hypervisor(slave)
		ssh = SSHExecutor.new(slave.ip, slave.username)
		result = ssh.exec(:xenserver_master_ha)
		raise "Could not change slave #{slave.ip} to master: (error number #{result[:status]}) #{result[:out]}" if result[:status] != 0
	end
	
	def send_critical_warning_for(exc)
	  logger.fatal "Critical error handling Hypervisor session: #{exc}"
	  Mailer.deliver_error_email(self.zone, exc)
		raise exc
  end
  
  def connect_to(host)
    Timeout::timeout(TIMEOUT, XenAPI::TimeoutError) {SessionFactory.create(host.ip, host.username, host.password)}
    logger.debug "Connection to host #{host.name} is OK"
    change_to_master_on_db(host)
		HypervisorConnection.hypervisor_session!(host.reload)
  end
  
	def logger
		@logger ||= Rails.logger
	end
end

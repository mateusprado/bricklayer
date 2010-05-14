module HypervisorConnection
  class << self
    def hypervisor_session(master)
      @session ||= hypervisor_session!(master)
    end

    def hypervisor_session!(master)
      Rails.logger.info "Connecting to hypervisor on #{master.ip} with user #{master.username}"
      @session = SessionFactory.create(master.ip, master.username, master.password) do |error, &called_method|
        Rails.logger.error(error)
        @session = HypervisorErrorHandler.new(master.zone, error).handle_error

        if called_method
          called_method.call(@session)
        else
          @session
        end
      end
    end

    def close_hypervisor_session!
      @session.close unless @session.nil?
      @session = nil
    end

  end

  def hypervisor_session
    HypervisorConnection.hypervisor_session(self.zone.master)
  end
end

::ActiveRecord::Base.send(:include, HypervisorConnection)

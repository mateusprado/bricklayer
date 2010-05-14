namespace :nephelae do

  namespace :consumers do

    ALL_CONSUMERS = [:template_cloner, :dhcp, :installation_setup, :installer,
                     :vnc_proxy, :snapshot_manager, :state_manager, :firewall_manager]

    desc "Print status for all consumers"
    task :status => :environment do
      puts '##### CONSUMERS STATUS #####'
      ALL_CONSUMERS.each do |consumer|
        status = status_of consumer
        puts "\# #{consumer}: #{status}"
      end
      puts '############################'
    end
    
    namespace :start do
      desc "Start the consumers for cloning templates"
      task :template_cloner => :environment do
        daemon :template_cloner do
          TemplateCloner.new.start
        end
      end

      desc "Start the consumer for dhcp handling"
      task :dhcp => :environment do
        daemon :dhcp do
          DHCPSynchronizer.new.start
        end
      end

      desc "Start the consumer for the installation setup"
      task :installation_setup => :environment do
        daemon :installation_setup do
          InstallationSetup.new.start
        end
      end

      desc "Start the consumer for the vm installer"
      task :installer => :environment do
        daemon :installer do
          Installer.new.start
        end
      end

      desc "Start the consumer for the vnc proxy synchronizer"
      task :vnc_proxy => :environment do
        daemon :vnc_proxy do
          VncProxySynchronizer.new.start
        end
      end
      
      desc "Start the consumer for snapshot management"
      task :snapshot_manager => :environment do
        daemon :snapshot_manager do
          SnapshotManager.new.start
        end
      end
      
      desc "Start the consumer for managing virtual machine states"
      task :state_manager => :environment do
        daemon :state_manager do
          StateManager.new.start
        end
      end
      
      desc "Start the consumer for managing firewall rule"
      task :firewall_manager => :environment do
        daemon :firewall_manager do
          FirewallManager.new.start
        end
      end

      desc "Start all consumers"
      task :all => ALL_CONSUMERS
    end
    
    namespace :stop do
      desc "Stop the consumer for cloning templates"
      task :template_cloner => :environment do
        kill :template_cloner
      end
      
      desc "Stop the consumer for dhcp handling"
      task :dhcp => :environment do
        kill :dhcp
      end    

      desc "Stop the consumer for the installation setup"
      task :installation_setup => :environment do
        kill :installation_setup
      end
      
      desc "Stop the consumer for the vm installer"
      task :installer => :environment do
        kill :installer
      end

      desc "Stop the consumer for the vnc proxy synchronizer"
      task :vnc_proxy => :environment do
        kill :vnc_proxy
      end
      
      desc "Stop the consumer for the snapshot management"
      task :snapshot_manager => :environment do
        kill :snapshot_manager
      end
      
      desc "Stop the consumer for managing virtual machine states"
      task :state_manager => :environment do
        kill :state_manager
      end
      
      desc "Stop the consumer for managing firewall rules"
      task :firewall_manager => :environment do
        kill :firewall_manager
      end
      
      desc "Stop all consumers"
      task :all => ALL_CONSUMERS
    end
    
    def daemon(process)
      if status_of(process) == :running
        puts "Daemon for #{process} is already running"
        return nil
      end

      puts "Starting #{process} daemon"
      pid = fork do
        yield

        loop do
          sleep(10000)
        end
        
        # Should never reach
        Process.exit
      end
      
      File.open(pid_file_for(process), 'w') {|f| f.write(pid) }
      Process.detach pid
    end
    
    def status_of(process)
      pid = pid_for process
      return :stopped unless pid
      
      begin
        Process.kill(0, pid)
        :running
      rescue Errno::ESRCH
        :stopped
      end
    end
    
    def pid_for(process)
      begin
        pid = nil
        file = pid_file_for(process)
        File.open(file, "r") {|f| pid = f.gets}
        pid.to_i == 0 ? nil : pid.to_i
      rescue Errno::ENOENT
        nil
      end
    end
    
    def pid_file_for(process)
      "/tmp/nephelae-#{process}.pid"
    end
    
    def kill(process)
      pid = pid_for process
      unless pid
        puts "WARN: No pid found for process #{process}"
        return
      end
      
      begin
        puts "Killing #{process} using PID #{pid}"
        Process.kill("KILL", pid)
      rescue Errno::ESRCH
        puts "WARN: No process found for pid #{pid}"
      end
      File.delete pid_file_for(process)
    end
    
  end
end

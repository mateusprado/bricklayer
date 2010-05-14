namespace :nephelae do
  desc "Checks if all hosts have the required keys in order to ssh work"
  task :check_ssh => :environment do
    zones = Zone.all
    zones.each do |zone|
      check_hosts_ssh_for(zone)  
    end
  end

  private
  def check_hosts_ssh_for(zone)
    zone.hosts.each do |host|
      check_ssh_for(host)
    end
  end

  def check_ssh_for(host)
    ssh = SSHExecutor.new(host.ip, host.username)
    begin
      ssh.exec :ssh_check
      host.ssh_key_connecting = true
    rescue 
      puts "Failed to connect to #{host.ip} through ssh - reason: #{$!.class}"
      host.ssh_key_connecting = false
    end
    puts "Could not save host #{host.ip}" unless host.save
  end
end

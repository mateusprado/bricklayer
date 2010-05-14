namespace :nephelae do
  desc "Synchronizes all zones caching its hosts"
  task :sync_zones => :environment do
    zones = Zone.all
    zones.each do |zone|
      sync_hosts_for(zone)  
    end
  end

  private
  def sync_hosts_for(zone)
    puts "Error while updating availability zone #{zone.name}: #{zone.errors.on :master}" unless zone.save_and_update_hosts
  end
end

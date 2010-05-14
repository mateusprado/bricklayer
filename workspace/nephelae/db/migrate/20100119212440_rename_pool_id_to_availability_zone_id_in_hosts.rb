class RenamePoolIdToAvailabilityZoneIdInHosts < ActiveRecord::Migration
  def self.up
    rename_column :hosts, :pool_id, :availability_zone_id
  end

  def self.down
    rename_column :hosts, :availability_zone_id, :pool_id
  end
end

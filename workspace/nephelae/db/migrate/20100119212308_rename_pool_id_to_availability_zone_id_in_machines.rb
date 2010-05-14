class RenamePoolIdToAvailabilityZoneIdInMachines < ActiveRecord::Migration
  def self.up
    rename_column :virtual_machines, :pool_id, :availability_zone_id
  end

  def self.down
    rename_column :virtual_machines, :availability_zone_id, :pool_id
  end
end

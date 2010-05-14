class RenameAvailabilityZonesToZones < ActiveRecord::Migration
  def self.up
    rename_column :virtual_machines, :availability_zone_id, :zone_id
    rename_column :hosts, :availability_zone_id, :zone_id
    rename_column :matrix_machines, :availability_zone_id, :zone_id
    rename_table :availability_zones, :zones
  end

  def self.down
    rename_column :virtual_machines, :zone_id, :availability_zone_id
    rename_column :hosts, :zone_id, :availability_zone_id
    rename_column :matrix_machines, :zone_id, :availability_zone_id
    rename_table :zones, :availability_zones
  end
end

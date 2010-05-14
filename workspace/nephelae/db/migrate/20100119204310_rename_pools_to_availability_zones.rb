class RenamePoolsToAvailabilityZones < ActiveRecord::Migration

  def self.up
    rename_table :pools, :availability_zones
  end

  def self.down
    rename_table :availability_zones, :pools
  end

end

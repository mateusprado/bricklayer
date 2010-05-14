class RenamePoolIdToAvailabilityZoneIdInMatrixMachines < ActiveRecord::Migration
  def self.up
    rename_column :matrix_machines, :pool_id, :availability_zone_id
  end

  def self.down
    rename_column :matrix_machines, :availability_zone_id, :pool_id
  end
end

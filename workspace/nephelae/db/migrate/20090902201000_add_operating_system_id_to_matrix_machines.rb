class AddOperatingSystemIdToMatrixMachines < ActiveRecord::Migration
  def self.up
    add_column :matrix_machines, :operating_system_id, :integer
  end

  def self.down
    remove_column :matrix_machines, :operating_system_id
  end
end

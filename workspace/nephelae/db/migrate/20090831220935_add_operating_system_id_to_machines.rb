class AddOperatingSystemIdToMachines < ActiveRecord::Migration
  def self.up
    add_column :virtual_machines, :operating_system_id, :integer
    add_index :virtual_machines, :operating_system_id
  end

  def self.down
    remove_column :virtual_machines, :operating_system_id
  end
end

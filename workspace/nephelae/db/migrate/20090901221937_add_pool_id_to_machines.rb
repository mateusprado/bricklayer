class AddPoolIdToMachines < ActiveRecord::Migration
  def self.up
    add_column :virtual_machines, :pool_id, :integer
    add_index :virtual_machines, :pool_id
  end

  def self.down
    remove_column :virtual_machines, :pool_id
  end
end

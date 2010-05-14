class AddVlanIdToVirtualMachines < ActiveRecord::Migration
  def self.up
    add_column :virtual_machines, :vlan_id, :integer
    add_index :virtual_machines, :vlan_id
  end

  def self.down
    remove_column :virtual_machines, :vlan_id
  end
end

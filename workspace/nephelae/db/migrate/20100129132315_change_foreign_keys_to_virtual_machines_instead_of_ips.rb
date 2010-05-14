class ChangeForeignKeysToVirtualMachinesInsteadOfIps < ActiveRecord::Migration
  def self.up
    add_column :virtual_machines, :private_ip_id, :integer
    add_column :virtual_machines, :public_ip_id, :integer
    remove_column :ips, :virtual_machine_id
    add_index :virtual_machines, :private_ip_id
    add_index :virtual_machines, :public_ip_id
  end

  def self.down
    remove_column :virtual_machines, :private_ip_id, :integer
    remove_column :virtual_machines, :public_ip_id, :integer
    add_column :ips, :virtual_machine_id, :integer
    add_index :ips, :virtual_machine_id
  end
end

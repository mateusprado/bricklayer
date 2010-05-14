class AlterIpsToPublicIps < ActiveRecord::Migration
  def self.up
    rename_column :ips, :vm, :virtual_machine_id
    rename_column :ips, :ip_range, :ip_range_id
    rename_table :ips, :public_ips
    
    add_index :public_ips, :ip_range_id
    add_index :public_ips, :virtual_machine_id
  end

  def self.down
    rename_column :public_ips, :virtual_machine_id, :vm
    rename_column :public_ips, :ip_range_id, :ip_range
    rename_table :public_ips, :ips
  end
end

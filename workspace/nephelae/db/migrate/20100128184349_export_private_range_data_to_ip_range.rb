class ExportPrivateRangeDataToIpRange < ActiveRecord::Migration
  def self.up
    remove_column :vlans, :ip
    remove_column :vlans, :mask
    add_column :ip_ranges, :vlan_id, :integer
    
    add_index :ip_ranges, :vlan_id
  end

  def self.down
    add_column :vlans, :ip, :string
    add_column :vlans, :mask, :integer
    remove_column :ip_ranges, :vlan_id
  end
end

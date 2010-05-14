class RenameIpColumnToAddressOnipsAndIpRanges < ActiveRecord::Migration
  def self.up
    rename_column :ips, :ip, :address
    rename_column :ip_ranges, :ip, :address
  end

  def self.down
    rename_column :ips, :address, :ip
    rename_column :ip_ranges, :address, :ip
  end
end

class RemoveIpsFromIpRange < ActiveRecord::Migration
  def self.up
    remove_column :ip_ranges, :ips
  end

  def self.down
    add_column :ip_ranges, :ips, :integer
  end
end

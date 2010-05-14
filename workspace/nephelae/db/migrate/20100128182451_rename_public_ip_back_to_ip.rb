class RenamePublicIpBackToIp < ActiveRecord::Migration
  def self.up
    rename_table :public_ips, :ips
  end

  def self.down
    rename_table :ips, :public_ips
  end
end

class AddPortToVncProxy < ActiveRecord::Migration
  def self.up
    add_column :vnc_proxies, :port, :integer
  end

  def self.down
    remove_column :vnc_proxies, :port
  end
end

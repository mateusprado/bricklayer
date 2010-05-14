class AddVncProxyToVncConsole < ActiveRecord::Migration
  def self.up
    add_column :vnc_consoles, :vnc_proxy_id, :integer
  end

  def self.down
    remove_column :vnc_consoles, :vnc_proxy_id
  end
end

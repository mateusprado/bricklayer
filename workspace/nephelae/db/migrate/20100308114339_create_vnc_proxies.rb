class CreateVncProxies < ActiveRecord::Migration
  def self.up
    create_table :vnc_proxies do |t|
      t.string :address
      t.integer :zone_id

      t.timestamps
    end
  end

  def self.down
    drop_table :vnc_proxies
  end
end

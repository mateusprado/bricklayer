class CreateFirewalls < ActiveRecord::Migration
  def self.up
    create_table :firewalls do |t|
      t.string :ip_address

      t.timestamps
    end
  end

  def self.down
    drop_table :firewalls
  end
end

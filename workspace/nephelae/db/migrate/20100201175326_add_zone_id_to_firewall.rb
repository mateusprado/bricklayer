class AddZoneIdToFirewall < ActiveRecord::Migration
  def self.up
    add_column :firewalls, :zone_id, :integer
  end

  def self.down
    remove_column :firewalls, :zone_id
  end
end

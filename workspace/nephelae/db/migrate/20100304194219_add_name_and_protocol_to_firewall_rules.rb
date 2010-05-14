class AddNameAndProtocolToFirewallRules < ActiveRecord::Migration
  def self.up
    change_table :firewall_rules do |t|
      t.remove :src_addr
      t.remove :dst_addr
      t.remove :firewall_id
      t.remove :port

      t.string :description
      t.string :filter_protocol
      t.string :filter_address
      t.integer :filter_port
    end
  end

  def self.down
    change_table :firewall_rules do |t|
      t.remove :description
      t.remove :filter_protocol
      t.remove :filter_address
      t.remove :filter_port

      t.string :src_addr
      t.string :dst_addr
      t.integer :firewall_id
      t.integer :port
    end
  end
end

class CreateFirewallRules < ActiveRecord::Migration
  def self.up
    create_table :firewall_rules do |t|
      t.string :rule_type
      t.string :src_addr
      t.string :dst_addr
      t.integer :port
      t.integer :firewall_id

      t.timestamps
    end
  end

  def self.down
    drop_table :firewall_rules
  end
end

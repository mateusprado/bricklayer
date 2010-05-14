class FixTypeColumnOnFirewallRules < ActiveRecord::Migration
  def self.up
    remove_column :firewall_rules, :rule_type
    add_column :firewall_rules, :type, :string
  end

  def self.down
    remove_column :firewall_rules, :type
    add_column :firewall_rules, :rule_type, :string
  end
end

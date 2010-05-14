class AddStateToFirewallRule < ActiveRecord::Migration
  def self.up
    add_column :firewall_rules, :status, :string
  end

  def self.down
    remove_column :firewall_rules, :status
  end
end

class AddVirtualMachineIdToFirewallRules < ActiveRecord::Migration
  def self.up
    add_column :firewall_rules, :virtual_machine_id, :integer
  end

  def self.down
    remove_column :firewall_rules, :virtual_machine_id
  end
end

class AddStateToVirtualMachine < ActiveRecord::Migration
  def self.up
    add_column :virtual_machines, :state, :string
  end

  def self.down
    remove_column :virtual_machines, :state
  end
end

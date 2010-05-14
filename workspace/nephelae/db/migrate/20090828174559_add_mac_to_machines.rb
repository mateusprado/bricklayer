class AddMacToMachines < ActiveRecord::Migration
  def self.up
    add_column :virtual_machines, :mac, :string
  end

  def self.down
    remove_column :virtual_machines, :mac
  end
end

class AddPasswordToVirtualMachine < ActiveRecord::Migration
  def self.up
    add_column :virtual_machines, :password, :string
  end

  def self.down
    remove_column :virtual_machines, :password
  end
end

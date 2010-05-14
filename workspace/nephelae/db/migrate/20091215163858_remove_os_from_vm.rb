class RemoveOsFromVm < ActiveRecord::Migration
  def self.up
    remove_column :virtual_machines, :os
  end

  def self.down
    add_column :virtual_machines, :os, :string
  end
end

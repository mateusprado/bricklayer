class AddCpusIntegerToVirtualMachines < ActiveRecord::Migration
  def self.up
    add_column :virtual_machines, :cpus, :integer
  end

  def self.down
    remove_column :virtual_machines, :cpus
  end
end

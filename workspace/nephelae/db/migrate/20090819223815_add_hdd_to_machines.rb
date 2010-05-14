class AddHddToMachines < ActiveRecord::Migration
  def self.up
    add_column :virtual_machines, :hdd, :integer
  end

  def self.down
    remove_column :virtual_machines, :hdd
  end
end

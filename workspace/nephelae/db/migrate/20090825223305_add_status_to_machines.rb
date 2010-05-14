class AddStatusToMachines < ActiveRecord::Migration
  def self.up
    add_column :virtual_machines, :status, :string, :default => "NOT_CREATED"
  end

  def self.down
    remove_column :virtual_machines, :status
  end
end

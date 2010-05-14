class RemoveDefaultStatusFromVm < ActiveRecord::Migration
  def self.up
    change_column :virtual_machines, :status, :string, :default => nil
  end

  def self.down
    change_column :virtual_machines, :status, :string, :default => "NOT_CREATED"
  end
end

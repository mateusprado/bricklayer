class AddPriorityToPool < ActiveRecord::Migration
  def self.up
    add_column :pools, :priority, :integer
  end

  def self.down
    remove_column :pools, :priority
  end
end

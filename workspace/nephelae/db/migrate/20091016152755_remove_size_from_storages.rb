class RemoveSizeFromStorages < ActiveRecord::Migration
  def self.up
    remove_column :storages, :size
  end

  def self.down
    add_column :storages, :size, :decimal, :precision => 40
  end
end

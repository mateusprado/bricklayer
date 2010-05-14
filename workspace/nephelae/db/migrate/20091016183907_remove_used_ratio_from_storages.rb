class RemoveUsedRatioFromStorages < ActiveRecord::Migration
  def self.up
  	remove_column :storages, :used_ratio
  end

  def self.down
  	add_column :storages, :used_ratio, :float
  end
end

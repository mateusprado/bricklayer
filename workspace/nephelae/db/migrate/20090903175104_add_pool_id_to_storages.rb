class AddPoolIdToStorages < ActiveRecord::Migration
  def self.up
    add_column :storages, :pool_id, :integer
  end

  def self.down
    remove_column :storages, :pool_id
  end
end

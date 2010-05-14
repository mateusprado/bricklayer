class RemoveStorageFromDb < ActiveRecord::Migration
  def self.up
    drop_table :storages
  end

  def self.down
    create_table :storages do |t|
      t.string :uuid
      t.string :name
      t.integer :size
      t.float :used_ratio
      t.integer :pool_id
    end
  end
end

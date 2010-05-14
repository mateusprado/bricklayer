class CreateStorages < ActiveRecord::Migration
  def self.up
    create_table :storages do |t|
      t.string :uuid
      t.string :name
      t.integer :size
      t.float :used_ratio
    end
  end

  def self.down
    drop_table :storages
  end
end

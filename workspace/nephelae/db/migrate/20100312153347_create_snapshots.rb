class CreateSnapshots < ActiveRecord::Migration
  def self.up
    create_table :snapshots do |t|
      t.string :name
      t.string :uuid
      t.integer :virtual_machine_id
      t.datetime :taken_at
    end
    add_index :snapshots, :virtual_machine_id
  end

  def self.down
    drop_table :snapshots
  end
end

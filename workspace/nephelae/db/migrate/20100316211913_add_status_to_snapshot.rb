class AddStatusToSnapshot < ActiveRecord::Migration
  def self.up
    add_column :snapshots, :status, :string
  end

  def self.down
    remove_column :snapshots, :status
  end
end

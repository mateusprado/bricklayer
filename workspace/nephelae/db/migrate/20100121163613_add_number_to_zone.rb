class AddNumberToZone < ActiveRecord::Migration
  def self.up
    add_column :zones, :number, :integer
  end

  def self.down
    remove_column :zones, :number
  end
end

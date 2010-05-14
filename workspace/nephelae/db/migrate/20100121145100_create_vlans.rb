class CreateVlans < ActiveRecord::Migration
  def self.up
    create_table :vlans do |t|
      t.integer :number
      t.string :ip
      t.integer :mask
      t.integer :zone_id
      t.timestamps
    end
    
    add_index :vlans, :zone_id
  end

  def self.down
    drop_table :vlans
  end
end

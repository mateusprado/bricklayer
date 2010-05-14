class CreateIpRanges < ActiveRecord::Migration
  def self.up
    create_table :ip_ranges do |t|
      t.string :from
      t.string :to
      t.integer :ips

      t.timestamps
    end
  end

  def self.down
    drop_table :ip_ranges
  end
end

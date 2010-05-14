class CreateIps < ActiveRecord::Migration
  def self.up
    create_table :ips do |t|
      t.integer :ip_range
      t.string :ip
      t.integer :vm

      t.timestamps
    end
  end

  def self.down
    drop_table :ips
  end
end

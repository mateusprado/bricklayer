class CreateHosts < ActiveRecord::Migration
  def self.up
    
    create_table :hosts do |t|
      t.string :name
      t.string :ip
      t.string :username
      t.string :password
      t.boolean :is_master, :default => false
    end

  add_index :hosts, :ip, :unique => true

  end

  def self.down
    
    drop_table :hosts
    
  end
end

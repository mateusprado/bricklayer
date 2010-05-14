class CreateDhcp < ActiveRecord::Migration
  def self.up
  	create_table :dhcps do |t|
      t.string :ip
      t.string :username
    end
  end

  def self.down
  	drop_table :dhcps
  end
end

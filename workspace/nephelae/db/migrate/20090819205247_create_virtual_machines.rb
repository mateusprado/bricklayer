class CreateVirtualMachines < ActiveRecord::Migration
  def self.up
    create_table :virtual_machines do |t|
      t.string :name
      t.string :uuid
      t.string :os
      t.integer :memory
      t.string :public_ip
      t.timestamps
    end
  end

  def self.down
    drop_table :virtual_machines
  end
end

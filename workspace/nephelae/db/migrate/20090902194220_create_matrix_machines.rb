class CreateMatrixMachines < ActiveRecord::Migration
  def self.up
    create_table :matrix_machines do |t|
      t.string :name
      t.string :uuid
      t.references :pool
    end
    
    add_index :matrix_machines, :uuid, :unique => true
  end

  def self.down
    drop_table :matrix_machines
  end
end

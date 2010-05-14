class CreateOperatingSystems < ActiveRecord::Migration
  def self.up
    create_table :operating_systems do |t|
      t.string :code
      t.string :description
    end
    
    add_index :operating_systems, :code, :unique => true
  end

  def self.down
    drop_table :operating_systems
  end
end

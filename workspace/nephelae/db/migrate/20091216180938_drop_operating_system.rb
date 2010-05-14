class DropOperatingSystem < ActiveRecord::Migration
  def self.up
    drop_table :operating_systems
  end

  def self.down
    create_table :operating_systems, :force => true do |t|
      t.string :code
      t.string :description
    end

    add_index "operating_systems", ["code"], :name => "index_operating_systems_on_code", :unique => true
  end
end

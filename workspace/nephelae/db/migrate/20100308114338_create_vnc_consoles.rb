class CreateVncConsoles < ActiveRecord::Migration
  def self.up
    create_table :vnc_consoles do |t|
      t.integer :port
      t.string :password
      t.integer :virtual_machine_id

      t.timestamps
    end
  end

  def self.down
    drop_table :vnc_consoles
  end
end

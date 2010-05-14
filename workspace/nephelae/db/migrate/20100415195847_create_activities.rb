class CreateActivities < ActiveRecord::Migration
  def self.up
    create_table :activities do |t|
      t.string :level
      t.text :message, :backtrace
      t.references :virtual_machine
      t.timestamps
    end
  end

  def self.down
    drop_table :activities
  end
end

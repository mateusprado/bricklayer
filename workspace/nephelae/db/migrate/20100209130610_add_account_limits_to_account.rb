class AddAccountLimitsToAccount < ActiveRecord::Migration
  def self.up
    change_table :accounts do |t|
      t.column :maximum_machine_count, :integer
      t.column :maximum_memory, :integer
      t.column :maximum_hdd, :integer
      t.column :maximum_cpus, :integer
    end
  end

  def self.down
    change_table :accounts do |t|
      t.remove :maximum_machine_count
      t.remove :maximum_memory
      t.remove :maximum_hdd
      t.remove :maximum_cpus
    end
  end
end

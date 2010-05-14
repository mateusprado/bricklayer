class AddMinimumVmSpecToSystemImages < ActiveRecord::Migration
  def self.up
    change_table :system_images do |t|
      t.integer :minimum_memory
      t.integer :minimum_hdd
      t.integer :minimum_cpus
    end
  end

  def self.down
    change_table :system_images do |t|
      t.remove :minimum_memory
      t.remove :minimum_hdd
      t.remove :minimum_cpus
    end
  end
end

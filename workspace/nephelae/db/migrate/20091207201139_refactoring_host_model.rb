class RefactoringHostModel < ActiveRecord::Migration
  def self.up
    rename_column :hosts, :is_master, :master
    change_column :hosts, :master, :boolean, :default => false, :null => false
  end

  def self.down
    change_column :hosts, :master, :boolean, :default => false, :null => true
    rename_column :hosts, :master, :is_master
  end
end

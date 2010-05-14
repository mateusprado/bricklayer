class AddNameToSystemImages < ActiveRecord::Migration
  def self.up
    add_column :system_images, :name, :string
  end

  def self.down
    remove_column :system_images, :name
  end
end

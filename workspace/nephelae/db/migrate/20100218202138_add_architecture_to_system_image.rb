class AddArchitectureToSystemImage < ActiveRecord::Migration
  def self.up
    add_column :system_images, :architecture, :integer
  end

  def self.down
    remove_column :system_images, :architecture
  end
end

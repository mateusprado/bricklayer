class RenameOperatingSystemIdToSystemImageId < ActiveRecord::Migration
  def self.up
    rename_column :matrix_machines, :operating_system_id, :system_image_id
    rename_column :virtual_machines, :operating_system_id, :system_image_id
  end

  def self.down
    rename_column :matrix_machines, :system_image_id, :operating_system_id
    rename_column :virtual_machines, :system_image_id, :operating_system_id
  end
end

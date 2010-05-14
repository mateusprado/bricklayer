class AddTemplateUuidToVirtualMachines < ActiveRecord::Migration
  def self.up
    add_column :virtual_machines, :template_uuid, :string
  end

  def self.down
    remove_column :virtual_machines, :template_uuid
  end
end

class AddTemplateInfoToMatrixMachines < ActiveRecord::Migration
  def self.up
    add_column :matrix_machines, :template_uuid, :string
    add_column :matrix_machines, :template_copies, :integer
  end

  def self.down
    remove_column :matrix_machines, :template_uuid
    remove_column :matrix_machines, :template_copies
  end
end

class AddCreatingTemplateFlagToMatrixMachines < ActiveRecord::Migration
  def self.up
    add_column :matrix_machines, :creating_template, :boolean
  end

  def self.down
    remove_column :matrix_machines, :creating_template
  end
end

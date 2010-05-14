class RemoveCreatingTemplateFromMatrixMachines < ActiveRecord::Migration
  def self.up
    change_table :matrix_machines do |t|
      t.remove :creating_template
    end
  end

  def self.down
    change_table :matrix_machines do |t|
      t.boolean :creating_template
    end
  end
end

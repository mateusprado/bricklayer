class AddPublicUuidVm < ActiveRecord::Migration
  def self.up
    add_column :virtual_machines, :public_uuid, :string
  end

  def self.down
    remove_column :virtual_machines, :public_uuid
  end
end

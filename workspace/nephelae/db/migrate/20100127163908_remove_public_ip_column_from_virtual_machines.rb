class RemovePublicIpColumnFromVirtualMachines < ActiveRecord::Migration
  def self.up
    remove_column :virtual_machines, :public_ip
  end

  def self.down
    add_column :virtual_machines, :public_ip, :string
  end
end

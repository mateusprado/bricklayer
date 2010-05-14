class AddPoolIdToHosts < ActiveRecord::Migration
  def self.up
    add_column :hosts, :pool_id, :integer
  end

  def self.down
    remove_column :hosts, :pool_id
  end
end

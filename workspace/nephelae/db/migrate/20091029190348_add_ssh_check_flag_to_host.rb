class AddSshCheckFlagToHost < ActiveRecord::Migration
  def self.up
    add_column :hosts, :ssh_key_connecting, :boolean
  end

  def self.down
    remove_column :hosts, :ssh_key_connecting
  end
end

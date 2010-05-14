class CreateAccounts < ActiveRecord::Migration
  def self.up
    create_table :accounts do |t|
      t.string :login
      t.timestamps
    end
    
    add_column :virtual_machines, :account_id, :integer
    add_index :virtual_machines, :account_id
  end

  def self.down
    remove_column :virtual_machines, :account_id
    drop_table :accounts
  end
end

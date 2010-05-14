class RenameIpRangeColumns < ActiveRecord::Migration
  def self.up
    remove_column :ip_ranges, :from
    remove_column :ip_ranges, :to
    add_column :ip_ranges, :ip, :string
    add_column :ip_ranges, :mask, :integer
  end

  def self.down
    remove_column :ip_ranges, :ip
    remove_column :ip_ranges, :mask
    add_column :ip_ranges, :from, :string
    add_column :ip_ranges, :to, :string
  end
end

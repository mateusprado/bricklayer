class CreateSystemImages < ActiveRecord::Migration
  def self.up
    create_table :system_images do |t|
      t.string :code
      t.string :description

      t.timestamps
    end
    add_index "system_images", ["code"], :name => "index_system_images_on_code"
  end

  def self.down
    drop_table :system_images
  end
end

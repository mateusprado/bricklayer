class CreateProcessingErrors < ActiveRecord::Migration
  def self.up
    create_table :processing_errors do |t|
      t.string :consumer
      t.string :error_message
      t.string :queue_message
      t.timestamps
    end
  end

  def self.down
    drop_table :processing_errors
  end
end

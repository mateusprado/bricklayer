ActiveRecord::Schema.define(:version => 0) do
  create_table :users do |t|
    t.string :name
  end
  
  create_table :things do |t|
    t.string :name
    t.references :user
  end
end
class CreateDgmTypeAttributes < ActiveRecord::Migration[7.1]
  def change
    create_table :dgm_type_attributes, id: false do |t|
      t.integer :typeID, null: false
      t.integer :attributeID, null: false
      t.integer :valueInt
      t.float :valueFloat
      t.timestamps
    end
    # Add composite primary key
    execute "ALTER TABLE dgm_type_attributes ADD PRIMARY KEY (\"typeID\", \"attributeID\");"
  end
end

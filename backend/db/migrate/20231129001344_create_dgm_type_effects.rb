class CreateDgmTypeEffects < ActiveRecord::Migration[7.1]
  def change
    create_table :dgm_type_effects, id: false do |t|
      t.integer :typeID, null: false
      t.integer :effectID, null: false
      t.boolean :isDefault
      t.timestamps
    end

    # Add composite primary key
    execute "ALTER TABLE dgm_type_effects ADD PRIMARY KEY (\"typeID\", \"effectID\");"
  end
end

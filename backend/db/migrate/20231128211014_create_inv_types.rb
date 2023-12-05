class CreateInvTypes < ActiveRecord::Migration[7.1]
  def change
    create_table :inv_types, id: false do |t|
      t.integer :typeID, null: false
      t.integer :groupID
      t.string :typeName, limit: 100
      t.text :description
      t.float :mass
      t.float :volume
      t.float :capacity
      t.integer :portionSize
      t.integer :raceID
      t.decimal :basePrice, precision: 19, scale: 4
      t.boolean :published
      t.integer :marketGroupID
      t.integer :iconID
      t.integer :soundID
      t.integer :graphicID

      t.timestamps
    end

    add_index :inv_types, :typeID, unique: true
    add_index :inv_types, :groupID
    change_column_default :inv_types, :published, from: nil, to: true
  end
end

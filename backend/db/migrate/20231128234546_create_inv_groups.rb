class CreateInvGroups < ActiveRecord::Migration[7.1]
  def change
    create_table :inv_groups, id: false do |t|
      t.integer :groupID
      t.integer :categoryID
      t.string :groupName
      t.integer :iconID
      t.boolean :useBasePrice
      t.boolean :anchored
      t.boolean :anchorable
      t.boolean :fittableNonSingleton
      t.boolean :published

      t.timestamps
    end
    add_index :inv_groups, :groupID, unique: true
    add_index :inv_groups, :categoryID
  end
end
